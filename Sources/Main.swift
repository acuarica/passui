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
    private let gpg: Gpg?

    @State private var gpgErrorMessage: String?

    init() {
        do {
            gpg = try Gpg()
        } catch {
            gpg = nil
            _gpgErrorMessage = State(initialValue: error.localizedDescription)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 12) {
                Readme(folder: passRootDir)
                Entries(folder: passRootDir)
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            StatusBar(left: "asdfasdf jksdkjsdjksd jksdjksd", right: "sdjksdjk")
        }
        .frame(width: 480, height: 800)
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

struct Gpg {
    private let gpgPath: String

    init() throws {
        // self.gpgPath = try Gpg.getGpgPath()
        self.gpgPath = ""
        // print("GPG path", self.gpgPath)
    }

    private static func getGpgPath() throws -> String {
        let process = Process()
        let stdOut = Pipe()
        let stdErr = Pipe()

        process.standardOutput = stdOut
        process.standardError = stdErr
        process.arguments = ["-c", "which gpg"]
        process.executableURL = URL(fileURLWithPath: "/bin/sh")
        try process.run()

        let out = try readToEOF(stdOut)
        let err = try readToEOF(stdErr)

        process.waitUntilExit()
        guard process.terminationStatus == 0 else {
            throw CommandError.commandFailed(out)
        }
        guard err.isEmpty else {
            throw CommandError.commandFailed(err)
        }

        return out.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

private func readToEOF(_ pipe: Pipe) throws -> String {
    let outData = pipe.fileHandleForReading.readDataToEndOfFile()
    guard let text = String(data: outData, encoding: .utf8) else {
        throw CommandError.invalidData
    }
    return text
}

private func gpgInfo(_ path: String) -> String {
    do {
        let (_, err) = try shell("gpg --list-packets " + path)
        return err
    } catch {
        return "no info"
    }
}

private func gpgDecrypt(_ path: String) throws -> String {
    let (out, _) = try shell("gpg --decrypt " + path)
    return out
}

private enum CommandError: Error {
    case commandFailed(String)
    // case parsingFailed
    case invalidData
    // case emptyOutput
}

private func shell(_ command: String) throws -> (String, String) {
    print("Running command", command)

    let process = Process()
    let stdOut = Pipe()
    let stdErr = Pipe()

    process.standardOutput = stdOut
    process.standardError = stdErr
    process.arguments = ["-c", command]
    process.executableURL = URL(fileURLWithPath: "/bin/sh")

    try process.run()

    let outData = stdOut.fileHandleForReading.readDataToEndOfFile()
    guard let out = String(data: outData, encoding: .utf8) else {
        throw CommandError.invalidData
    }

    let errData = stdErr.fileHandleForReading.readDataToEndOfFile()
    guard let err = String(data: errData, encoding: .utf8) else {
        throw CommandError.invalidData
    }

    // Bundle().executablePath()
    process.waitUntilExit()
    guard process.terminationStatus == 0 else {
        throw CommandError.commandFailed(out)
    }

    print(err)
    print(out)

    return (out, err)
}
