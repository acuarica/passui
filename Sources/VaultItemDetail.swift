import SwiftUI

struct VaultItemDetail: View {
    let item: VaultItem
    let gpg: Gpg

    @State private var info: String?
    @State private var content: String?

    @State private var isCopied = false
    @State private var isExpanded: Bool = false

    // DisclosureGroup(isExpanded: $isExpanded) {
    // } label: {
    // Text("asdfasdfasdfasd").foregroundStyle(.secondary)
    // }

    var body: some View {
        // HStack(alignment: .top) {
        VStack(alignment: .leading, spacing: 22) {
            headerView()
            Divider()
            contentView()
            infoView()
        }
        // }
        .padding(20)
        .task(id: item) {
            info = try? gpg.info(item.url.path)
            content = nil
            content = try? gpg.decrypt(item.url.path)
        }
    }

    private func headerView() -> some View {
        HStack {
            Text(item.label)
                .font(.system(size: 18))
                .padding(.trailing, 10)
            Text(".\(item.url.pathExtension)")
                .padding(4)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.cyan.opacity(0.3))
                )
            Spacer()
            Text(item.url.lastPathComponent)
                .foregroundStyle(.secondary)
                .font(.caption)
                .tooltip(item.url.path)
        }
    }

    private func infoView() -> some View {
        GroupBox {
            if let info {
                Text(info)
                    .textSelection(.enabled)
            } else {
                Text("error could not load gpg info")
            }
        } label: {
            Label("GPG Info", systemImage: "info.circle")
        }
    }

    private func contentView() -> some View {
        GroupBox {

            if let content {
                HStack {

                    Text(content)
                        .textSelection(.enabled)
                    Spacer()
                }

                Button {
                    secureCopy(text: content)
                    withAnimation {
                        isCopied = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        withAnimation {
                            isCopied = false
                        }
                    }

                } label: {
                    Label(
                        isCopied ? "Copied (Clears in 30s)" : "Copy Secret",
                        systemImage: isCopied ? "checkmark" : "doc.on.doc"
                    )
                    .padding(3)
                }
                .buttonStyle(.borderedProminent)

            } else {
                Text("error could not load gpg detail")
            }
        } label: {
            Label("", systemImage: "lock.open")
        }
    }
}
