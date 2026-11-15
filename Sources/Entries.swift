import SwiftUI

struct VaultItemRow: View {
    let item: VaultItem

    var body: some View {
        HStack(alignment: .top) {
            Image(systemName: "lock.doc")
                .resizable()
                .scaledToFit()
                .frame(width: 24, height: 24)
                .padding(.top, 4)
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(item.label)
                        .font(.system(size: 14))

                    Text(".\(item.url.pathExtension)")
                        .padding(4)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.cyan.opacity(0.3))
                        )

                }
                Text("Created: \(Self.formatDate(item.createdAt))")
                    .foregroundStyle(.secondary)
                Text("Last Modified: \(Self.formatDate(item.modifiedAt))")
                    .foregroundStyle(.secondary)
            }
            .font(.caption)
        }
        .padding(8)
    }

    private static func formatDate(_ date: Date?) -> String {
        return date?.formatted(date: .abbreviated, time: .shortened) ?? "Unavailable"
    }
}

struct VaultItemDetail: View {
    let url: URL
    let gpg: Gpg

    @State private var info: String?
    @State private var detail: String?

    var body: some View {
        VStack {
            Text(url.lastPathComponent)
            Divider()
            if let info {
                Text(info)
                    .textSelection(.enabled)
            } else {
                Text("error could not load gpg info")
            }
            Divider()
            if let detail {
                Text(detail)
                    .textSelection(.enabled)
            } else {
                Text("error could not load gpg detail")
            }
            Spacer()
            Text("")
        }
        .padding()
        .onAppear(perform: loadGpgInfoAndDecrypt)
    }

    private func loadGpgInfoAndDecrypt() {
        info = try? gpg.info(url.path)
        detail = try? gpg.decrypt(url.path)
    }
}
