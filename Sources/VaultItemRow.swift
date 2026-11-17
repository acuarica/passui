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
                Text("Created: \(formatDate(item.createdAt))")
                    .foregroundStyle(.secondary)
                Text("Last Modified: \(formatDate(item.modifiedAt))")
                    .foregroundStyle(.secondary)
            }
            .font(.caption)
        }
        .padding(8)
    }

}
