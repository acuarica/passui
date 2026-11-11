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
    private let passRootDir: URL = {
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
    }()

    private var gpg: Result<(Gpg, Result<Version, any Error>), any Error> = {
        do {
            let gpg = Gpg(execPath: try getGpgExecPath())
            do {
                return .success((gpg, .success(try gpg.version())))
            } catch {
                return .success((gpg, .failure(error)))
            }
        } catch {
            return .failure(error)
        }
    }()

    var body: some View {
        VStack(spacing: 0) {
            VSplit(
                top: {
                    Readme(folder: passRootDir)
                        .frame(idealHeight: 200)
                },
                bottom: {
                    Entries(folder: passRootDir, gpg: try? gpg.get().0)
                        .frame(idealHeight: 600)
                }
            )
            .padding()
            switch gpg {
            case .success(let gpg):
                StatusBar(
                    left: { Text("gpg").tooltip(gpg.0.execPath) },
                    right: {
                        switch gpg.1 {
                        case .success(let version):
                            Text(version.number).tooltip(version.info)
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
        }
        .frame(width: 480, height: 800)
    }
}
