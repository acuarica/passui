import Foundation

struct Vault {
    let folder: URL

    // func loadDirectory() -> Result<[VaultItem], any Error> {
    //     print("Loading vault items from", folder, "...")
    //     do {
    //         let items: [VaultItem] = try FileManager.default.contentsOfDirectory(
    //             at: folder,
    //             includingPropertiesForKeys: [
    //                 .isDirectoryKey, .creationDateKey, .contentModificationDateKey,
    //             ],
    //             options: .skipsHiddenFiles
    //         )
    //         .map { url in
    //             let values = try url.resourceValues(forKeys: [
    //                 .isDirectoryKey, .creationDateKey, .contentModificationDateKey,
    //             ])
    //             return VaultItem(
    //                 url: url,
    //                 isDirectory: values.isDirectory ?? false,
    //                 createdAt: values.creationDate,
    //                 modifiedAt: values.contentModificationDate
    //             )
    //         }
    //         .filter {
    //             $0.isDirectory || $0.url.pathExtension == "gpg" || $0.url.pathExtension == "asc"
    //         }
    //         .sorted {
    //             $0.url.lastPathComponent.localizedStandardCompare($1.url.lastPathComponent)
    //                 == .orderedAscending
    //         }
    //         return .success(items)
    //     } catch {
    //         print(">", error)
    //         return .failure(error)
    //     }
    // }

    func load() -> [VaultFolder]? {
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
