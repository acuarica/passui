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

    @State private var gpgVersion: (String, String)?
    @State private var gpgPath: String?
    @State private var gpgPathErrorMessage: String?

    var body: some View {
        VStack(spacing: 0) {
            VSplit(
                top: {
                    Readme(folder: passRootDir)
                        .frame(idealHeight: 200)
                },
                bottom: {
                    Entries(folder: passRootDir)
                        .frame(idealHeight: 600)
                }
            )
            .padding()
            if let e = gpgPathErrorMessage {
                StatusBar(
                    left: { Text(e) },
                    right: { Text("error") }
                )
            } else if let p = gpgPath {
                StatusBar(
                    left: { Text("gpg").tooltip(p) },
                    right: { Text(gpgVersion!.0).tooltip(gpgVersion!.1) }
                )
            }
        }
        .frame(width: 480, height: 800)
        .onAppear(perform: loadGpgPath)
    }

    private func loadGpgPath() {
        do {
            let gpg = Gpg(execPath: try getGpgPath())

            gpgVersion = try gpg.version()
            gpgPath = gpg.execPath
            gpgPathErrorMessage = nil
        } catch {
            gpgVersion = nil
            gpgPath = nil
            gpgPathErrorMessage = error.localizedDescription
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
