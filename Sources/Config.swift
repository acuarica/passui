import Foundation

struct Config: Decodable {
    let passRoot: String?
    let gpg: GpgConfig?
    let readme: String?

    struct GpgConfig: Decodable {
        let execName: String?
        let execPath: String?
    }

    static func load() -> Config {
        let configRoot =
            if let xdgConfigHome = ProcessInfo.processInfo.environment["XDG_CONFIG_HOME"],
                xdgConfigHome.hasPrefix("/")
            {
                URL(fileURLWithPath: xdgConfigHome, isDirectory: true)
            } else {
                FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(
                    ".config", isDirectory: true)
            }
        let passConfigFile = configRoot.appendingPathComponent("passui", isDirectory: true)
            .resolvingSymlinksInPath()
            .appendingPathComponent("passui.json")
        print("PassUI config", passConfigFile)

        do {
            let data = try Data(contentsOf: passConfigFile)
            let config = try JSONDecoder().decode(Config.self, from: data)
            print(">", config)
            return config
        } catch {
            print(">", error)
            return Config(passRoot: nil, gpg: GpgConfig(execName: nil, execPath: nil), readme: nil)
        }
    }
}
