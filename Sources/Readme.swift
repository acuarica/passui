import SwiftUI

struct Readme: View {
    let readmeURL: URL
    let content: Result<String, any Error>

    var body: some View {
        switch content {
            case .success(let content):
                ZStack(alignment: .topTrailing) {
                    ScrollView {
                        Text(LocalizedStringKey(content))
                            .textSelection(.enabled)
                    }
                    Label(readmeURL.lastPathComponent, systemImage: "book")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.blue.opacity(0.2))
                        )
                        .tooltip(readmeURL.path)
                }
                .padding()
            case .failure(let error):
                ContentUnavailableView(
                    "Couldn't load README",
                    systemImage: "exclamationmark.triangle",
                    description: Text(error.localizedDescription).foregroundStyle(.orange)
                )
        }
    }
}
