import Foundation

func loadVault(folder: URL) -> [VaultFolder]? {
    print("Loading vault items from", folder)

    var isDirectory: ObjCBool = false
    guard FileManager.default.fileExists(atPath: folder.path, isDirectory: &isDirectory) else {
        return nil
        // throw EnumerationError.directoryNotFound(resolvedURL)
    }

    guard isDirectory.boolValue else {
        return nil
        // throw EnumerationError.notADirectory(resolvedURL)
    }

    let resourceKeys: [URLResourceKey] = [
        .isDirectoryKey, .creationDateKey, .contentModificationDateKey,
    ]
    let ls = FileManager.default.enumerator(
        at: folder,
        includingPropertiesForKeys: resourceKeys,
        options: .skipsHiddenFiles
    )!

    var tree: [URL: [VaultItem]] = [folder: []]
    for case let url as URL in ls {
        guard let values = try? url.resourceValues(forKeys: Set(resourceKeys)) else {
            continue
        }

        if let isDirectory = values.isDirectory, isDirectory {
            assert(tree[url] == nil, "Directory already exists")
            tree[url] = []
        } else if url.pathExtension == "gpg" || url.pathExtension == "asc" {
            let key = url.deletingLastPathComponent()
            assert(tree[key] != nil, "Directory does not exist for file")
            tree[key]!.append(
                VaultItem(
                    url: url,
                    createdAt: values.creationDate,
                    modifiedAt: values.contentModificationDate
                ))
        }
    }
    return
        tree
        .map { VaultFolder(url: $0, items: $1) }
        .sorted { $0.url.path.compare($1.url.path) == .orderedAscending }
}

struct VaultFolder: Identifiable, Hashable {
    var id: String { url.path }

    let url: URL
    let items: [VaultItem]
}

struct VaultItem: Identifiable, Hashable {
    var id: String { url.path }

    let url: URL
    let createdAt: Date?
    let modifiedAt: Date?

    var label: String {
        url.deletingPathExtension().deletingPathExtension().lastPathComponent
            .replacingOccurrences(of: "_", with: " ")
            .replacingOccurrences(of: "-", with: " ")
            .capitalized
    }
}
