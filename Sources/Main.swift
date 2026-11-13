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

        dirs = Vault(folder: passRootDir).load()
        self.selectedCategory = dirs[0]

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

    private let dirs: [VaultFolder]

    @State private var selectedCategory: VaultFolder?

    @State private var items: Result<[VaultItem], any Error>?
    @State private var searchText: String = ""
    @State private var selection: VaultItem? = nil

    var body: some View {
        VStack(spacing: 2) {
            NavigationSplitView {

                List(selection: $selectedCategory) {
                    ForEach(dirs, id: \.self) { category in
                        Text(category.url.lastPathComponent)
                    }
                }
                .navigationTitle("Sidebar title")

                // ForEach(items, id: \.self) { item in
                // VaultItemView(item: item)
                // .tag(item)

            } content: {
                if let items {
                    switch items {
                        case .success(let items):
                            List(selection: $selection) {
                                ForEach(items, id: \.self) { item in
                                    VaultItemView(item: item)
                                        .tag(item)
                                }
                            }
                            .navigationDestination(for: VaultItem.self) { url in
                                if case let .success(gpg) = gpg {
                                    DetailView(url: url.url, gpg: gpg.0)
                                } else {
                                    ContentUnavailableView(
                                        "Couldn't decrypt vault item",
                                        systemImage: "exclamationmark.triangle",
                                        description: Text("GPG not available")
                                    )
                                }
                            }
                            .searchable(text: $searchText, prompt: "Search vault items...")
                        case .failure(let error):
                            Text("\(error)")
                    }
                } else {
                    Text("more err")

                    if let items = selectedCategory?.items {
                        List(selection: $selection) {
                            ForEach(items, id: \.self) { item in
                                VaultItemView(item: item)
                                    .tag(item)
                            }
                        }
                    }

                }
            } detail: {
                if let selection {
                    if case let .success(gpg) = gpg {
                        DetailView(url: selection.url, gpg: gpg.0)
                    } else {
                        Text("err gpg")
                    }
                } else {
                    if let readme {
                        switch readme.1 {
                            case .success(let content):
                                readmeView(fileURL: readme.0, content: content)
                                    .padding()
                            case .failure(let error):
                                ContentUnavailableView(
                                    "Couldn't load \(readme.0.lastPathComponent)",
                                    systemImage: "exclamationmark.triangle",
                                    description: Text("\(error)")
                                )
                        }
                    } else {
                        ContentUnavailableView(
                            "Select an item",
                            systemImage: "folder"
                        )
                    }
                }
            }
            .toolbar {
                Button("refresh", systemImage: "arrow.clockwise", action: loadItems)
                if readme != nil {
                    Button("readme", systemImage: "book", action: { selection = nil })
                }
            }
            .onAppear(perform: loadItems)
            statusBar()
        }
    }

    private func loadItems() {
        // items = Vault(folder: passRootDir).loadDirectory()
    }

    @ViewBuilder private func statusBar() -> some View {
        HStack {
            switch gpg {
                case .success(let gpg):
                    Text(URL(fileURLWithPath: gpg.0.execPath).lastPathComponent)
                        .tooltip(gpg.0.execPath)
                    Spacer()
                    switch gpg.1 {
                        case .success(let version):
                            Text(version.number).tooltip(version.info)
                        case .failure(let error):
                            Text("gpg version: \(error)").foregroundStyle(.orange)
                    }
                case .failure(let error):
                    Text("gpg: \(error)").foregroundStyle(.orange)
            }
        }
        .foregroundStyle(.primary)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color.indigo.opacity(0.3))
    }

    @ViewBuilder private func readmeView(fileURL: URL, content: String) -> some View {
        ZStack(alignment: .topTrailing) {
            ScrollView {
                Text(LocalizedStringKey(content))
                    .textSelection(.enabled)
            }
            Label(fileURL.lastPathComponent, systemImage: "book")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.blue.opacity(0.2))
                )
                .tooltip(fileURL.path)
        }
    }
}
