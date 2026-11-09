import SwiftUI

struct Entries: View {
    let folder: URL

    @State private var items: [VaultItem] = []
    @State private var errorMessage: String?

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
                        NavigationLink(value: item.url) {
                            HStack(alignment: .top) {
                                Image(systemName: item.isDirectory ? "folder" : "lock.doc")
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
                                    Text(item.createdAtLabel)
                                        .foregroundStyle(.secondary)
                                    Text(item.modifiedAtLabel)
                                        .foregroundStyle(.secondary)
                                }
                                .font(.caption)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .padding(.top, 20)
                            }
                            .padding(8)
                        }

                        // NavigationLink {
                        //     ColorDetail(color: .mint, text: item.url.lastPathComponent)
                        // }

                        // Button {
                        // handleItemClick(item)
                        // } label: {
                        // .frame(maxWidth: .infinity, alignment: .leading)
                        // .contentShape(Rectangle())
                        // }

                        // Text("Detail view for \(item)")
                        // .navigationTitle("Friend")
                        // .navigationBarTitleDisplayMode(.inline)
                        // }

                    }
                    .listStyle(.bordered)
                    .navigationDestination(for: URL.self) { url in
                        VStack {
                            Text(url.lastPathComponent)
                            Divider()
                            // Text(gpgInfo(url.path))
                            // Divider()
                            // Text((try? gpgDecrypt(url.path)) ?? "no")
                            Spacer()
                            Text(url.lastPathComponent)
                        }
                    }

                    .navigationTitle("Frameworks")

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
            .filter { url in url.pathExtension == "gpg" || url.pathExtension == "asc" }
            .map { url in
                let values = try url.resourceValues(forKeys: [
                    .isDirectoryKey, .creationDateKey, .contentModificationDateKey,
                ])
                return VaultItem(
                    url: url,
                    isDirectory: values.isDirectory ?? false,
                    createdAt: values.creationDate,
                    modifiedAt: values.contentModificationDate
                )
            }
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

private struct VaultItem: Identifiable {
    var id: String { url.path }

    let url: URL
    let isDirectory: Bool
    let createdAt: Date?
    let modifiedAt: Date?

    var label: String {
        url.deletingPathExtension().deletingPathExtension().lastPathComponent
            .replacingOccurrences(of: "_", with: " ")
            .replacingOccurrences(of: "-", with: " ")
            .capitalized
    }

    var createdAtLabel: String { "Created: \(VaultItem.formatDate(createdAt))" }
    var modifiedAtLabel: String { "Last Modified: \(VaultItem.formatDate(modifiedAt))" }

    private static func formatDate(_ date: Date?) -> String {
        return date?.formatted(date: .abbreviated, time: .shortened) ?? "Unavailable"
    }
}
