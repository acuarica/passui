import SwiftUI

@main
struct DirectoryMenuBarApp: App {
    var body: some Scene {
        MenuBarExtra("Directory Files", systemImage: "lock.rectangle") {
            DirectoryContentsView()
        }
        .menuBarExtraStyle(.window)
    }
}

private struct DirectoryContentsView: View {
    private let passRootDir = getPassRootDir()
    private let gpg: Gpg?

    @State private var items: [DirectoryItem] = []
    @State private var gpgErrorMessage: String?
    @State private var errorMessage: String?
    @State private var openErrorMessage: String?

    init() {
        do {
            gpg = try Gpg()
        } catch {
            gpg = nil
            _gpgErrorMessage = State(initialValue: error.localizedDescription)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            if let readme = passRootDir.2 {
                Text(LocalizedStringKey(readme)).lineLimit(10)
            }
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(
                        passRootDir.0 == passRootDir.1
                            ? passRootDir.0.lastPathComponent
                            : "\(passRootDir.0.lastPathComponent) (\(passRootDir.1.lastPathComponent))"
                    )
                    .font(.headline)
                    .help(passRootDir.1.path)
                    Text("\(items.count) items")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button(action: loadDirectory) {
                    Image(systemName: "arrow.clockwise")
                }
                .buttonStyle(.borderless)
                .help("Refresh")
            }

            if let gpgErrorMessage {
                ContentUnavailableView(
                    "Couldn't load gpg",
                    systemImage: "exclamationmark.triangle",
                    description: Text(gpgErrorMessage)
                )
            } else if let errorMessage {
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
                            HStack {
                                Label(
                                    toLabelName(item.url),
                                    systemImage: item.isDirectory ? "folder" : "lock.doc"
                                )
                                .help(item.url.path)
                                .font(.system(size: 14))
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
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
                            Text(gpgInfo(url.path))
                            Divider()
                            Text((try? gpgDecrypt(url.path)) ?? "no")
                            Spacer()
                            Text(url.lastPathComponent)
                        }
                    }
                }
            }

            if let openErrorMessage {
                Text(openErrorMessage)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
        .padding()
        .frame(width: 380, height: 640)
        .onAppear(perform: loadDirectory)
    }

    private func handleItemClick(_ item: DirectoryItem) {
        // guard NSWorkspace.shared.open(item.url) else {
        //     openErrorMessage = "Couldn't open \(item.url.lastPathComponent)."
        //     return
        // }

        // openErrorMessage = nil
        do {
            let _ = try gpgDecrypt(item.url.path)
        } catch {
            openErrorMessage = "Couldn't open \(item.url.lastPathComponent)."
        }
    }

    private func loadDirectory() {
        do {
            let urls = try FileManager.default.contentsOfDirectory(
                at: passRootDir.1,
                includingPropertiesForKeys: [.isDirectoryKey],
                options: .skipsHiddenFiles
            ).filter { url in url.pathExtension == "gpg" || url.pathExtension == "asc" }
            items =
                try urls
                .map { url in
                    DirectoryItem(
                        url: url,
                        isDirectory: try url.resourceValues(forKeys: [.isDirectoryKey]).isDirectory
                            ?? false
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

private struct DirectoryItem: Identifiable {
    let url: URL
    let isDirectory: Bool

    var id: String { url.path }
}

private func toLabelName(_ item: URL) -> String {
    item.deletingPathExtension().deletingPathExtension().lastPathComponent
        .replacingOccurrences(of: "_", with: " ")
        .replacingOccurrences(of: "-", with: " ")
        .capitalized
}

private func getPassRootDir() -> (URL, URL, String?) {
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
    print("Loading password items from", dirURL)

    let readme = try? String(
        contentsOf: resolvedURL.appendingPathComponent("README.md"), encoding: .utf8)

    return (dirURL, resolvedURL, readme)
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
