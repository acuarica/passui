import Foundation

private enum CommandError: Error {
    case invalidData
    case commandFailed(exitCode: Int32, out: String, err: String)
}

func getGpgExecPath() throws -> String {
    print("Locating GPG binary...")

    let process = Process()
    let stdOut = Pipe()
    let stdErr = Pipe()

    process.standardOutput = stdOut
    process.standardError = stdErr
    process.arguments = ["-i", "-c", "which gpg"]
    process.executableURL = URL(fileURLWithPath: "/bin/bash")
    try process.run()
    process.waitUntilExit()

    let out = try readToEOF(stdOut)
    let err = try readToEOF(stdErr)

    guard process.terminationStatus == 0 else {
        throw CommandError.commandFailed(exitCode: process.terminationStatus, out: out, err: err)
    }
    guard err.isEmpty else {
        throw CommandError.commandFailed(exitCode: 0, out: out, err: err)
    }

    let path = out.trimmingCharacters(in: .whitespacesAndNewlines)
    print("> GPG executable found in", path)
    return path
}

struct Version {
    let number: String
    let info: String
}

struct Gpg {
    let execPath: String

    func version() throws -> Version {
        let (out, err) = try gpg(["--version"])
        guard err.isEmpty else {
            throw CommandError.commandFailed(exitCode: 0, out: out, err: err)
        }

        let number = out.split(whereSeparator: \.isNewline)[0...1].joined(separator: "/")
        let info = out.components(separatedBy: "\n\n")[1].trimmingCharacters(
            in: .whitespacesAndNewlines)

        return Version(number: number, info: info)
    }

    func info(_ path: String) throws -> String {
        let (out, _) = try gpg(["--list-packets", path])
        return out
    }

    func decrypt(_ path: String) throws -> String {
        let (out, _) = try gpg(["--decrypt", path])
        return out
    }

    private func gpg(_ args: [String]) throws -> (String, String) {
        print("Running GPG", args)

        let process = Process()
        let stdOut = Pipe()
        let stdErr = Pipe()

        process.standardOutput = stdOut
        process.standardError = stdErr
        process.arguments = args
        process.executableURL = URL(fileURLWithPath: execPath)

        try process.run()
        process.waitUntilExit()

        let out = try readToEOF(stdOut)
        let err = try readToEOF(stdErr)

        guard process.terminationStatus == 0 else {
            throw CommandError.commandFailed(
                exitCode: process.terminationStatus, out: out, err: err)
        }

        return (out, err)
    }
}

private func readToEOF(_ pipe: Pipe) throws -> String {
    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    guard let text = String(data: data, encoding: .utf8) else {
        throw CommandError.invalidData
    }
    return text
}
