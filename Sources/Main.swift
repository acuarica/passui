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

    @State private var searchText: String = ""

    @State private var items: [VaultItem] = []
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
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 12) {
                Readme(folder: passRootDir.1)
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
                    // .buttonStyle(.borderless)
                    // .help("Refresh")
                    .tooltip {
                        Text("Refresh")
                        // .fixedSize()
                    }
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
                                HStack(alignment: .top) {
                                    Image(systemName: item.isDirectory ? "folder" : "lock.doc")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 24, height: 24)
                                        .padding(.top, 4)
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(toLabelName(item.url))
                                            .font(.system(size: 14))
                                        Text(item.createdAtLabel())
                                            .foregroundStyle(.secondary)
                                        Text(item.modifiedAtLabel())
                                            .foregroundStyle(.secondary)
                                    }
                                    .font(.caption)
                                    .help(item.url.path)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .padding(.top, 20)
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

                        .navigationTitle("Frameworks")
                        // .searchable(text: $searchText)
                        .searchable(
                            text: $searchText,
                            placement: .sidebar,
                            prompt: "Name or Brand"
                        )

                    }
                }

                if let openErrorMessage {
                    Text(openErrorMessage)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            StatusBar(left: "asdfasdf jksdkjsdjksd jksdjksd", right: "sdjksdjk")
            // .tooltip {
            //     Text("asdfasdf")
            //     Text("123324")
            //     Text("123324")
            // }
        }
        .frame(width: 480, height: 800)
        .onAppear(perform: loadDirectory)
    }

    private func handleItemClick(_ item: VaultItem) {
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
            items = try FileManager.default.contentsOfDirectory(
                at: passRootDir.1,
                includingPropertiesForKeys: [
                    .isDirectoryKey, .creationDateKey, .contentModificationDateKey,
                ],
                options: .skipsHiddenFiles
            )
            .filter { url in url.pathExtension == "gpg" || url.pathExtension == "asc" }
            .map { url in
                let values = try url.resourceValues(forKeys: [
                    .isDirectoryKey, .creationDateKey, .contentModificationDateKey,
                ])
                return VaultItem(
                    url: url,
                    isDirectory: values.isDirectory ?? false,
                    createdAt: values.creationDate,
                    modifiedAt: values.contentModificationDate
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

private struct VaultItem: Identifiable {
    var id: String { url.path }

    let url: URL
    let isDirectory: Bool
    let createdAt: Date?
    let modifiedAt: Date?

    func createdAtLabel() -> String {
        return "Created: \(VaultItem.formatDate(createdAt))"
    }

    func modifiedAtLabel() -> String {
        return "Last Modified: \(VaultItem.formatDate(modifiedAt))"
    }

    private static func formatDate(_ date: Date?) -> String {
        return date?.formatted(date: .abbreviated, time: .shortened) ?? "Unavailable"
    }
}

private func toLabelName(_ item: URL) -> String {
    item.deletingPathExtension().deletingPathExtension().lastPathComponent
        .replacingOccurrences(of: "_", with: " ")
        .replacingOccurrences(of: "-", with: " ")
        .capitalized
}

private func getPassRootDir() -> (URL, URL) {
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

    return (dirURL, resolvedURL)
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
