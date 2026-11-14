import SwiftUI

@main
struct PassUIApp: App {
    var body: some Scene {
        Window("PassUI :: Vault", id: "main-window") {
            ContentsView(config: Config.load())
        }
    }
}

private struct ContentsView: View {
    private let passRootDir: URL
    private let gpg: Result<(Gpg, Result<Version, any Error>), any Error>
    private let readme: (URL, Result<String, Error>)?

    init(config: Config) {
        passRootDir =
            if let passRoot = config.passRoot {
                URL(fileURLWithPath: passRoot)
            } else {
                FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(
                    ".password-store", isDirectory: true
                ).resolvingSymlinksInPath()
            }
        print("Pass root folder", passRootDir)

        folders = Vault(folder: passRootDir).load()!
        self.selectedFolder = folders[0]

        do {
            let gpg = Gpg(
                execPath: try config.gpg?.execPath
                    ?? getGpgExecPath(for: config.gpg?.execName ?? "gpg"))
            do {
                self.gpg = .success((gpg, .success(try gpg.version())))
            } catch {
                self.gpg = .success((gpg, .failure(error)))
            }
        } catch {
            self.gpg = .failure(error)
        }

        if let showReadme = config.showReadme, !showReadme {
            readme = nil
        } else {
            let fileName = config.readme ?? "README.md"
            let fileURL = passRootDir.appendingPathComponent(fileName)
            do {
                readme = (fileURL, .success(try String(contentsOf: fileURL, encoding: .utf8)))
            } catch {
                readme = config.readme != nil ? (fileURL, .failure(error)) : nil
            }
        }
    }

    private let folders: [VaultFolder]

    @State private var selectedFolder: VaultFolder?
    @State private var items: Result<[VaultItem], any Error>?
    @State private var searchText: String = ""
    @State private var selection: VaultItem? = nil

    var body: some View {
        VStack(spacing: 2) {
            NavigationSplitView {
                List(selection: $selectedFolder) {
                    Section("Folders") {
                        ForEach(folders, id: \.self) { folder in
                            HStack {
                                Label(folder.url.lastPathComponent, systemImage: "folder")
                                Spacer()
                                Text("\(folder.items.count) items")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                .listStyle(.sidebar)
            } content: {
                if let items = selectedFolder?.items {
                    List(selection: $selection) {
                        if items.isEmpty {
                            ContentUnavailableView(
                                "No items",
                                systemImage: "folder",
                                description: Text("This folder is empty.")
                            )
                        } else {
                            ForEach(items, id: \.self) { item in
                                VaultItemView(item: item)
                                    .tag(item)
                            }
                        }
                    }
                    .searchable(text: $searchText, prompt: "Search vault items...")
                }
            } detail: {
                if let selection {
                    if case let .success(gpg) = gpg {
                        DetailView(url: selection.url, gpg: gpg.0)
                    } else {
                        ContentUnavailableView(
                            "Couldn't decrypt vault item",
                            systemImage: "exclamationmark.triangle",
                            description: Text("GPG not available").foregroundStyle(.orange)
                        )
                    }
                } else {
                    if let readme {
                        Readme(readmeURL: readme.0, content: readme.1)
                    } else {
                        ContentUnavailableView(
                            "Select an item",
                            systemImage: "lock.doc"
                        )
                    }
                }
            }
            .toolbar {
                Text(passRootDir.path)
                Divider()
                Button("refresh", systemImage: "arrow.clockwise", action: loadItems)
                if readme != nil {
                    Button("readme", systemImage: "book", action: { selection = nil })
                }
            }
            .onAppear(perform: loadItems)
            StatusBar(gpg: gpg)
        }
    }

    private func loadItems() {
        // items = Vault(folder: passRootDir).loadDirectory()
    }
}
