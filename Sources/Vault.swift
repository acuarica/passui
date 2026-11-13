import Foundation

struct Vault {
    let folder: URL

    func loadDirectory() -> Result<[VaultItem], any Error> {
        print("Loading vault items from", folder, "...")
        do {
            let items: [VaultItem] = try FileManager.default.contentsOfDirectory(
                at: folder,
                includingPropertiesForKeys: [
                    .isDirectoryKey, .creationDateKey, .contentModificationDateKey,
                ],
                options: .skipsHiddenFiles
            )
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
            .filter {
                $0.isDirectory || $0.url.pathExtension == "gpg" || $0.url.pathExtension == "asc"
            }
            .sorted {
                $0.url.lastPathComponent.localizedStandardCompare($1.url.lastPathComponent)
                    == .orderedAscending
            }
            return .success(items)
        } catch {
            print(">", error)
            return .failure(error)
        }
    }
}

struct VaultItem: Identifiable, Hashable {
    var id: String { url.path }

    let url: URL
    let isDirectory: Bool
    let createdAt: Date?
    let modifiedAt: Date?

    var label: String {
        url.deletingPathExtension().deletingPathExtension().lastPathComponent
            .replacingOccurrences(of: "_", with: " ")
            .replacingOccurrences(of: "-", with: " ")
            .capitalized
    }
}
