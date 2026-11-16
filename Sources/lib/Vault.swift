import Foundation

private enum ListingError: Error {
    case folderNotFound(folder: URL)
    case notADirectory(folder: URL)
}

private class VaultFolderNode {
    let url: URL
    var children: [VaultFolderNode] = []
    var items: [VaultItem] = []

    init(_ url: URL) {
        self.url = url
    }

    func map() -> VaultFolder {
        VaultFolder(
            url: url,
            children: children.map(),
            items: items.sorted {
                $0.url.lastPathComponent.compare($1.url.lastPathComponent) == .orderedAscending
            }
        )
    }
}

extension Array where Element == VaultFolderNode {
    fileprivate func map() -> [VaultFolder]? {
        isEmpty
            ? nil
            : map { $0.map() }.sorted { $0.url.path.compare($1.url.path) == .orderedAscending }
    }
}

func loadVault(from folder: URL) throws -> [VaultFolder] {
    print("Loading vault items from", folder)

    var isDirectory: ObjCBool = false
    guard FileManager.default.fileExists(atPath: folder.path, isDirectory: &isDirectory) else {
        throw ListingError.folderNotFound(folder: folder)
    }

    guard isDirectory.boolValue else {
        throw ListingError.notADirectory(folder: folder)
    }

    let resourceKeys: [URLResourceKey] = [
        .isDirectoryKey, .creationDateKey, .contentModificationDateKey,
    ]
    let ls = FileManager.default.enumerator(
        at: folder,
        includingPropertiesForKeys: resourceKeys,
        options: .skipsHiddenFiles
    )!

    let root = [VaultFolderNode(folder)]
    var dict: [URL: VaultFolderNode] = [folder: root[0]]

    for case let url as URL in ls {
        let values = try url.resourceValues(forKeys: Set(resourceKeys))

        if let isDirectory = values.isDirectory, isDirectory {
            assert(dict[url] == nil, "Directory already exists")
            let parent = url.deletingLastPathComponent()
            assert(dict[parent] != nil, "Parent directory does not exist")
            let node = VaultFolderNode(url)
            dict[parent]!.children.append(node)
            dict[url] = node
        } else if url.pathExtension == "gpg" || url.pathExtension == "asc" {
            let key = url.deletingLastPathComponent()
            assert(dict[key] != nil, "Directory does not exist for file")
            dict[key]!.items.append(
                VaultItem(
                    url: url,
                    createdAt: values.creationDate,
                    modifiedAt: values.contentModificationDate
                ))
        }
    }

    return root.map() ?? []
}

struct VaultFolder: Identifiable, Hashable {
    var id: String { url.path }

    let url: URL
    let children: [VaultFolder]?
    let items: [VaultItem]

    var label: String {
        url.lastPathComponent
    }
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
            .components(separatedBy: .whitespaces)
            .map { $0.lowercased() == $0 && $0.count > 1 ? $0.capitalized : $0 }
            .joined(separator: " ")
    }
}
