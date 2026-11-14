import SwiftUI

struct Entries: View {
    let folder: URL
    let gpg: Gpg?

    @State private var items: [VaultItem] = []
    @State private var errorMessage: String?

    // FIX: WARNING: Application performed a reentrant operation in its NSTableView delegate. This warning will become an assert in the future.
    @State private var searchText: String = ""

    var body: some View {
        VStack {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Vault \(folder.lastPathComponent)")
                        .font(.headline)
                        .tooltip(folder.path)
                    Text("\(items.count) items")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "magnifyingglass").resizable().aspectRatio(contentMode: .fill)
                    .frame(width: 12, height: 12)
                    .padding(.leading, 5)
                    .opacity(0.8)
                TextField("Search vault items...", text: $searchText)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 200)
                Button(action: { searchText = "" }) {
                    Image(systemName: "xmark.circle.fill")
                }
                .padding(.trailing, 8)
                .disabled(searchText == "")
                .buttonStyle(.borderless)
                Divider()
                    .frame(height: 14)
                    .padding(.leading, 8)
                    .padding(.trailing, 8)

                Button(action: loadDirectory) {
                    Image(systemName: "arrow.clockwise")
                }
                .tooltip("Reload Vault Items")
            }

            if let errorMessage {
                ContentUnavailableView(
                    "Couldn't load directory",
                    systemImage: "exclamationmark.triangle",
                    description: Text(errorMessage)
                )
            } else if items.isEmpty {
                ContentUnavailableView(
                    "No items",
                    systemImage: "folder",
                    description: Text("This directory is empty.")
                )
            } else {
                NavigationStack {
                    List(items) { item in
                        if searchText.isEmpty
                            || item.label.localizedCaseInsensitiveContains(searchText)
                        {
                            NavigationLink(value: item.url) {
                                VaultItemView(item: item)
                            }
                        }
                    }
                    .listStyle(.bordered)
                    .navigationDestination(for: URL.self) { url in
                        if let gpg {
                            DetailView(url: url, gpg: gpg)
                        } else {
                            ContentUnavailableView(
                                "Couldn't decrypt vault item",
                                systemImage: "exclamationmark.triangle",
                                description: Text("GPG not available")
                            )
                        }
                    }
                    .navigationTitle("Vault Items")
                }
            }
        }
        .onAppear(perform: loadDirectory)
    }

    private func loadDirectory() {
        print("Loading vault items from", folder, "...")
        do {
            items = try FileManager.default.contentsOfDirectory(
                at: folder,
                includingPropertiesForKeys: [
                    .isDirectoryKey, .creationDateKey, .contentModificationDateKey,
                ],
                options: .skipsHiddenFiles
            )
            .map { url in
                let values = try url.resourceValues(forKeys: [
                    .isDirectoryKey, .creationDateKey, .contentModificationDateKey,
                ])
                return VaultItem(
                    url: url,
                    createdAt: values.creationDate,
                    modifiedAt: values.contentModificationDate
                )
            }
            .filter { $0.url.pathExtension == "gpg" || $0.url.pathExtension == "asc" }
            .sorted {
                $0.url.lastPathComponent.localizedStandardCompare($1.url.lastPathComponent)
                    == .orderedAscending
            }
            errorMessage = nil
        } catch {
            items = []
            errorMessage = error.localizedDescription
        }
    }
}

struct VaultItemView: View {
    let item: VaultItem

    var body: some View {
        HStack(alignment: .top) {
            Image(systemName: "lock.doc")
                .resizable()
                .scaledToFit()
                .frame(width: 24, height: 24)
                .padding(.top, 4)
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(item.label)
                        .font(.system(size: 14))

                    Text(".\(item.url.pathExtension)")
                        .padding(4)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.cyan.opacity(0.3))
                        )

                }
                Text("Created: \(VaultItemView.formatDate(item.createdAt))")
                    .foregroundStyle(.secondary)
                Text("Last Modified: \(VaultItemView.formatDate(item.modifiedAt))")
                    .foregroundStyle(.secondary)
            }
            .font(.caption)
        }
        .padding(8)
    }

    private static func formatDate(_ date: Date?) -> String {
        return date?.formatted(date: .abbreviated, time: .shortened) ?? "Unavailable"
    }
}

struct DetailView: View {
    let url: URL
    let gpg: Gpg

    @State private var info: String?
    @State private var detail: String?

    var body: some View {
        VStack {
            Text(url.lastPathComponent)
            Divider()
            if let info {
                Text(info)
                    .textSelection(.enabled)
            } else {
                Text("error could not load gpg info")
            }
            Divider()
            if let detail {
                Text(detail)
                    .textSelection(.enabled)
            } else {
                Text("error could not load gpg detail")
            }
            Spacer()
            Text("")
        }
        .padding()
        .onAppear(perform: loadGpgInfoAndDecrypt)
    }

    private func loadGpgInfoAndDecrypt() {
        info = try? gpg.info(url.path)
        detail = try? gpg.decrypt(url.path)
    }
}
