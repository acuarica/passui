import SwiftUI

struct VaultItemDetail: View {
    let item: VaultItem
    let gpg: Gpg

    @State private var content: String?
    @State private var info: String?

    @State private var isCopied = false

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            headerView()
            Divider()
            contentView()
            gpgInfoView()
            fileInfoView()
            Spacer()
        }
        .padding(20)
        .task(id: item) {
            content = nil
            content = try? gpg.decrypt(item.url.path)
            info = try? gpg.info(item.url.path)
        }
    }

    private func headerView() -> some View {
        HStack {
            Text(item.label)
                .font(.system(size: 18))
                .padding(.trailing, 8)
            Text(".\(item.url.pathExtension)")
                .padding(4)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.cyan.opacity(0.3))
                )
        }
    }

    private func contentView() -> some View {
        GroupBox {
            if let content {
                HStack {
                    SecureText(text: content)
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
            Label("Content", systemImage: "lock.open")
        }
    }

    private func gpgInfoView() -> some View {
        GroupBox {
            HStack {
                if let info {
                    Text(info)
                        .textSelection(.enabled)
                } else {
                    Text("error could not load gpg info")
                }
                Spacer()
            }
        } label: {
            Label("GPG Info", systemImage: "info.circle")
        }
    }

    private func fileInfoView() -> some View {
        GroupBox {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Path: \(item.url.path)")
                        .textSelection(.enabled)
                    Text("Created: \(formatDate(item.createdAt))")
                    Text("Last Modified: \(formatDate(item.modifiedAt))")
                }
                .font(.caption)
                Spacer()
            }
        } label: {
            Label("File Info", systemImage: "doc.circle")
        }
    }
}

struct SecureText: View {
    let text: String
    @State private var isRevealed = false

    var body: some View {
        Text(isRevealed ? text : "••••••••••••••••")
            .font(.system(.body, design: .monospaced))
            .textSelection(.enabled)
        Button {
            isRevealed.toggle()
        } label: {
            Image(systemName: isRevealed ? "eye.slash" : "eye")
                .accentColor(.gray)
        }
    }
}
