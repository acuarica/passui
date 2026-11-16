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

    @State private var rootFolder: Result<VaultFolder, any Error>?
    @State private var selectedFolder: VaultFolder?
    @State private var selectedItem: VaultItem?
    @State private var searchText = ""

    var body: some View {
        VStack(spacing: 2) {
            if let rootFolder {
                switch rootFolder {
                    case .success(let rootFolder):
                        foldersView(rootFolder)
                    case .failure(let error):
                        Spacer()
                        ContentUnavailableView(
                            "Couldn't load directory",
                            systemImage: "exclamationmark.triangle",
                            description: Text("\(error)")
                                .foregroundStyle(.orange)
                        )
                        Spacer()
                }
            }
            StatusBar(gpg: gpg)
        }
        .toolbar {
            Text(passRootDir.path)
            Divider()
            Button("refresh", systemImage: "arrow.clockwise", action: refresh)
            if readme != nil {
                Button("readme", systemImage: "book", action: { selectedItem = nil })
            }
        }
        .onAppear(perform: refresh)
    }

    private func refresh() {
        do {
            let rootFolder = try loadVault(from: passRootDir)
            self.rootFolder = .success(rootFolder)
            self.selectedFolder = rootFolder
        } catch {
            self.rootFolder = .failure(error)
        }
    }

    private func foldersView(_ rootFolder: VaultFolder) -> some View {
        NavigationSplitView {
            List(selection: $selectedFolder) {
                Section("Folders") {
                    TreeView([rootFolder], children: \.children) { folder in
                        Label(folder.label, systemImage: "folder")
                            .badge(folder.items.count)
                            .tag(folder)
                    }
                }
            }
            .listStyle(.sidebar)
            .onChange(of: selectedFolder) { searchText = "" }
        } content: {
            if let items = selectedFolder?.items {
                List(selection: $selectedItem) {
                    ForEach(items, id: \.self) { item in
                        if searchText.isEmpty
                            || item.label.localizedCaseInsensitiveContains(searchText)
                        {
                            VaultItemRow(item: item)
                                .tag(item)
                        }
                    }
                }
                .searchable(text: $searchText, prompt: "Search vault items...")
                .overlay {
                    if items.isEmpty {
                        ContentUnavailableView(
                            "No Items",
                            systemImage: "folder",
                            description: Text("This folder is empty.")
                        )
                    }
                }
            }
        } detail: {
            if let selectedItem {
                if case let .success(gpg) = gpg {
                    VaultItemDetail(item: selectedItem, gpg: gpg.0)
                } else {
                    ContentUnavailableView(
                        "Couldn't decrypt vault item",
                        systemImage: "exclamationmark.triangle",
                        description: Text("GPG not available")
                            .foregroundStyle(.orange)
                    )
                }
            } else {
                if let readme {
                    Readme(readmeURL: readme.0, content: readme.1)
                } else if let items = selectedFolder?.items, !items.isEmpty {
                    ContentUnavailableView(
                        "Select an item",
                        systemImage: "lock.doc"
                    )
                }
            }
        }
    }
}
