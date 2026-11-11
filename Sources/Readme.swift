import SwiftUI

struct Readme: View {
    let folder: URL

    var body: some View {
        if let (fileName, fileURL, content) = Readme.getContent(at: folder) {
            ZStack(alignment: .topTrailing) {
                ScrollView {
                    Text(LocalizedStringKey(content))
                        .textSelection(.enabled)
                }
                Label(fileName, systemImage: "book")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.blue.opacity(0.2))
                    )
                    .tooltip(fileURL.path)
            }
        }
    }

    private static func getContent(at folder: URL) -> (String, URL, String)? {
        let fileName = "README.md"
        let fileURL = folder.appendingPathComponent(fileName)
        return try? (fileName, fileURL, String(contentsOf: fileURL, encoding: .utf8))
    }
}
