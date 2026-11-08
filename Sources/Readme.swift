import SwiftUI

struct Readme: View {
    let folder: URL
    var body: some View {
        if let (fileName, content) = getReadmeContent() {
            ZStack(alignment: .topTrailing) {
                ScrollView {
                    Text(LocalizedStringKey(content))
                        .textSelection(.enabled)
                }
                .frame(height: 220)
                Label(fileName, systemImage: "book")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.blue.opacity(0.2))
                    )
                    .tooltip(folder.path)
            }
        }
    }

    private func getReadmeContent() -> (String, String)? {
        let fileName = "README.md"
        do {
            return try (
                fileName,
                String(
                    contentsOf: folder.appendingPathComponent(fileName), encoding: .utf8)
            )
        } catch {
            return nil
        }
    }
}
