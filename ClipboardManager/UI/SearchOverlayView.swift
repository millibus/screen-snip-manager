import SwiftUI

final class OverlayRefreshTrigger: ObservableObject {
    @Published var trigger = false
    func refresh() { trigger.toggle() }
}

/// Parses "tag:foo" from the start of query; returns (tag, restOfQuery).
private func parseTagFilter(_ query: String) -> (tag: String?, search: String) {
    let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
    let lower = "tag:"
    if q.lowercased().hasPrefix(lower) {
        let after = String(q.dropFirst(lower.count))
        if let space = after.firstIndex(where: { $0.isWhitespace }) {
            let tag = String(after[..<space]).trimmingCharacters(in: .whitespaces)
            let search = String(after[after.index(after: space)...]).trimmingCharacters(in: .whitespaces)
            return (tag.isEmpty ? nil : tag, search)
        }
        return (after.trimmingCharacters(in: .whitespaces), "")
    }
    return (nil, q)
}

private func tagsList(from tagsString: String?) -> [String] {
    guard let s = tagsString, !s.isEmpty else { return [] }
    return s.split(separator: ",").map { String($0).trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
}

struct SearchOverlayView: View {
    @State private var query = ""
    @State private var entries: [ClipboardEntry] = []
    @State private var selectedId: Int64?
    @State private var entryToTag: ClipboardEntry?
    @State private var newTagText = ""
    @State private var imageCache: [Int64: NSImage] = [:]
    @State private var debounceTask: Task<Void, Never>?
    @FocusState private var listFocused: Bool
    @ObservedObject var refreshTrigger: OverlayRefreshTrigger
    var onSelect: ((ClipboardEntry) -> Void)?
    var onDismiss: (() -> Void)?

    private let debounceNs: UInt64 = 120_000_000 // 120ms

    init(refreshTrigger: OverlayRefreshTrigger, onSelect: ((ClipboardEntry) -> Void)? = nil, onDismiss: (() -> Void)? = nil) {
        self.refreshTrigger = refreshTrigger
        self.onSelect = onSelect
        self.onDismiss = onDismiss
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Search clipboard history… (tag:name to filter by tag)", text: $query)
                    .textFieldStyle(.plain)
                    .onChange(of: query) { _, newValue in
                        debouncedRefresh(query: newValue)
                    }
                    .onKeyPress(.downArrow) {
                        listFocused = true
                        return .handled
                    }
            }
            .padding(10)
            .background(.ultraThinMaterial)

            Divider()

            List(entries, selection: $selectedId) { entry in
                HStack(alignment: .top, spacing: 8) {
                    Button {
                        ClipboardStore.shared.setPinned(entryId: entry.id, pinned: !entry.isPinned)
                        refreshEntries()
                    } label: {
                        Image(systemName: entry.isPinned ? "pin.fill" : "pin")
                            .foregroundStyle(entry.isPinned ? .orange : .secondary)
                            .font(.system(size: 12))
                    }
                    .buttonStyle(.plain)

                    if entry.contentType == .image {
                        if let nsImage = imageCache[entry.id] {
                            Image(nsImage: nsImage)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 40, height: 40)
                                .clipped()
                                .cornerRadius(4)
                        } else {
                            Color.secondary.opacity(0.2)
                                .frame(width: 40, height: 40)
                                .cornerRadius(4)
                                .task {
                                    if let data = ClipboardStore.shared.fetchImageData(for: entry.id), let img = NSImage(data: data) {
                                        imageCache[entry.id] = img
                                    }
                                }
                        }
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(entry.preview)
                            .lineLimit(2)
                            .truncationMode(.tail)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        let tags = tagsList(from: entry.tags)
                        if !tags.isEmpty {
                            Text(tags.map { "#\($0)" }.joined(separator: " "))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                                .truncationMode(.tail)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture(count: 1) {
                        selectedId = entry.id
                        var selectedEntry = entry
                        if selectedEntry.contentType == .image && selectedEntry.imageData == nil {
                            selectedEntry.imageData = ClipboardStore.shared.fetchImageData(for: selectedEntry.id)
                        }
                        onSelect?(selectedEntry)
                    }
                }
                .contextMenu {
                    Button("Add tag…") {
                        entryToTag = entry
                        newTagText = ""
                    }
                }
            }
            .listStyle(.plain)
            .focusable()
            .focused($listFocused)
            .onKeyPress(.downArrow) {
                moveSelection(by: 1)
                return .handled
            }
            .onKeyPress(.upArrow) {
                moveSelection(by: -1)
                return .handled
            }
            .onKeyPress(.return) {
                if var entry = entries.first(where: { $0.id == selectedId }) {
                    if entry.contentType == .image && entry.imageData == nil {
                        entry.imageData = ClipboardStore.shared.fetchImageData(for: entry.id)
                    }
                    onSelect?(entry)
                    onDismiss?()
                }
                return .handled
            }
            .onAppear {
                refreshEntries()
            }
            .onDisappear {
                debounceTask?.cancel()
                imageCache.removeAll()
            }
            .onChange(of: refreshTrigger.trigger) { _, _ in
                refreshEntries()
            }
        }
        .frame(width: 420, height: 360)
        .sheet(item: $entryToTag) { entry in
            AddTagSheet(entry: entry, tagText: $newTagText) {
                if !newTagText.trimmingCharacters(in: .whitespaces).isEmpty {
                    ClipboardStore.shared.addTag(entryId: entry.id, tag: newTagText.trimmingCharacters(in: .whitespaces))
                    refreshEntries()
                }
                entryToTag = nil
            } onCancel: {
                entryToTag = nil
            }
        }
    }

    private func debouncedRefresh(query currentQuery: String) {
        debounceTask?.cancel()
        debounceTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: debounceNs)
            guard !Task.isCancelled else { return }
            if query == currentQuery {
                refreshEntries()
            }
        }
    }

    private func refreshEntries() {
        let maxHistory = UserDefaults.standard.object(forKey: UserDefaultsKeys.maxHistory) as? Int ?? UserDefaultsKeys.maxHistoryDefault
        var all = ClipboardStore.shared.fetchEntriesWithoutImageData(limit: maxHistory)
        let (tagFilter, searchQuery) = parseTagFilter(query)
        if let tag = tagFilter, !tag.isEmpty {
            all = all.filter { tagsList(from: $0.tags).contains(tag) }
        }
        var result = FuzzySearchService.shared.search(all, query: searchQuery)
        result.sort { e1, e2 in
            if e1.isPinned != e2.isPinned { return e1.isPinned }
            return e1.createdAt > e2.createdAt
        }
        entries = result
        if let first = entries.first, selectedId == nil || !entries.contains(where: { $0.id == selectedId }) {
            selectedId = first.id
        }
    }

    private func moveSelection(by delta: Int) {
        guard let idx = entries.firstIndex(where: { $0.id == selectedId }) else {
            if let first = entries.first { selectedId = first.id }
            return
        }
        let newIdx = idx + delta
        if newIdx >= 0, newIdx < entries.count {
            selectedId = entries[newIdx].id
        }
    }
}

// Sheet for adding a tag; entry is identified so we need Binding for text only.
struct AddTagSheet: View {
    let entry: ClipboardEntry
    @Binding var tagText: String
    var onAdd: () -> Void
    var onCancel: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Text("Add tag to entry")
                .font(.headline)
            Text(entry.preview)
                .lineLimit(2)
                .truncationMode(.tail)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
            TextField("Tag name", text: $tagText)
                .textFieldStyle(.roundedBorder)
            HStack {
                Button("Cancel", action: onCancel)
                Button("Add", action: onAdd)
                    .keyboardShortcut(.return, modifiers: [])
            }
        }
        .padding(24)
        .frame(width: 320)
    }
}
