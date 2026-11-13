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
    // private let passRootDir123 = {
    //     let ss = FileManager.default.enumerator(at: resolvedURL, includingPropertiesForKeys: nil)!

    //     var fileURLs: [URL] = []
    //     let resourceKeys = Set<URLResourceKey>([.nameKey, .isDirectoryKey])
    //     var tree: [URL: [URL]] = [:]

    //     for case let fileURL as URL in ss {
    //         guard let resourceValues = try? fileURL.resourceValues(forKeys: resourceKeys),
    //             let isDirectory = resourceValues.isDirectory,
    //             let name = resourceValues.name
    //             else {
    //                 continue
    //         }
    //         if isDirectory {
    //         } else {
    //             print(fileURL)
    //             fileURLs.append(fileURL)
    //         }
    //     }
    //     // print(fileURLs)
    // }

    private let passRootDir: URL
    private let gpg: Result<(Gpg, Result<Version, any Error>), any Error>
    private let readme: String

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

        readme = config.readme ?? "README.md"
    }

    @State private var items: Result<[VaultItem], any Error>?
    @State private var searchText: String = ""

    @State private var selection: VaultItem? = nil

    var body: some View {
        NavigationSplitView {
            Text("sidebar")
                .navigationTitle("Sidebar title")

        } content: {
            if let items {

                switch items {
                    case .success(let items):
                        List(selection: $selection) {
                            ForEach(items, id: \.self) { item in
                                // NavigationLink {
                                //     VaultItemView(item: e)
                                // } label: {
                                //     VaultItemView(item: e)
                                // }

                                // NavigationLink(value: item) {
                                VaultItemView(item: item)
                                    .tag(item)
                                // }
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
                        // .navigationTitle("Vault Itemssdkjsdjksd")
                        .searchable(text: $searchText, prompt: "asdf and 1234")
                    // .searchable(text: $searchText)
                    case .failure(let error):
                        Text("\(error)")
                }

            } else {
                Text("more err")
            }
        } detail: {
            Readme(folder: passRootDir, readme: readme)
            if let selection {
                if case let .success(gpg) = gpg {
                    DetailView(url: selection.url, gpg: gpg.0)
                } else {
                    Text("err gpg")
                }
            } else {

                Text("det")
            }
        }
        .toolbar {
            Text("sdjksdsdjk")
            Spacer()
            Button("readme") {
                selection = nil
            }
        }
        .onAppear(perform: { items = Vault(folder: passRootDir).loadDirectory() })

        statusBar()

        VStack(spacing: 0) {
            // VSplit(
            //     top: {
            // Readme(folder: passRootDir)
            //             .frame(idealHeight: 200)
            //     },
            //     bottom: {
            // Entries(folder: passRootDir, gpg: try? gpg.get().0)
            // .frame(idealHeight: 600)
            //     }
            // )
            // .padding()
        }
    }

    @ViewBuilder private func statusBar() -> some View {
        HStack(spacing: 8) {
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
}
