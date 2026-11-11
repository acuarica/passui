import SwiftUI

@main
struct MenuBarApp: App {
    var body: some Scene {
        MenuBarExtra("Directory Files", systemImage: "lock.rectangle") {
            ContentsView()
        }
        .menuBarExtraStyle(.window)
    }
}

private struct ContentsView: View {
    private let passRootDir = getPassRootDir()

    @State private var gpgInfo: Result<(String, Result<(String, String), any Error>), any Error>?

    var body: some View {
        VStack(spacing: 0) {
            VSplit(
                top: {
                    Readme(folder: passRootDir)
                        .frame(idealHeight: 300)
                },
                bottom: {
                    Entries(folder: passRootDir)
                        .frame(idealHeight: 500)
                }
            )
            .padding()
            if let gpgInfo {
                switch gpgInfo {
                case .success(let gpgInfo):
                    StatusBar(
                        left: { Text("gpg").tooltip(gpgInfo.0) },
                        right: {
                            switch gpgInfo.1 {
                            case .success(let version):
                                Text(version.0).tooltip(version.1)
                            case .failure(let error):
                                Text("gpg version: \(error)")
                            }
                        }
                    )
                case .failure(let error):
                    StatusBar(
                        left: { Text("gpg: \(error)").foregroundStyle(.orange) },
                        right: { EmptyView() }
                    )
                }
            } else {
                StatusBar(left: { Text("...") }, right: { Text("") })
            }
        }
        .frame(width: 480, height: 800)
        .onAppear(perform: loadGpgInfo)
    }

    private func loadGpgInfo() {
        do {
            let execPath = try getGpgExecPath()
            let gpg = Gpg(execPath: execPath)
            do {
                gpgInfo = .success((execPath, .success(try gpg.version())))
            } catch {
                gpgInfo = .success((execPath, .failure(error)))
            }
        } catch {
            gpgInfo = .failure(error)
        }
    }
}

private func getPassRootDir() -> URL {
    let configRoot =
        if let xdgConfigHome = ProcessInfo.processInfo.environment["XDG_CONFIG_HOME"],
            xdgConfigHome.hasPrefix("/")
        {
            URL(fileURLWithPath: xdgConfigHome, isDirectory: true)
        } else {
            FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(
                ".config", isDirectory: true)
        }

    let dirURL = configRoot.appendingPathComponent("passui", isDirectory: true)
    let resolvedURL = dirURL.resolvingSymlinksInPath()
    print("Vault root folder", resolvedURL)

    return resolvedURL
}
