import SwiftUI

struct VaultItemDetail: View {
    let item: VaultItem
    let gpg: Gpg

    @State private var info: String?
    @State private var detail: String?

    @State private var msg = ""

    var body: some View {
        VStack {
            Text(item.url.lastPathComponent)
            Divider()
            Text(msg)
            TabView {
                VStack {
                    if let info {
                        Text(info)
                            .textSelection(.enabled)
                    } else {
                        Text("error could not load gpg info")
                    }
                    // Divider()
                }.tabItem {
                    Label("Info", systemImage: "info.circle")
                }
                VStack {
                    if let detail {
                        Text(detail)
                            .textSelection(.enabled)
                    } else {
                        Text("error could not load gpg detail")
                    }
                    // Spacer()
                    // Text("")
                }.tabItem {
                    Label("Details", systemImage: "book")
                }
            }
            // .tabViewStyle()

        }
        .padding()
        .task(id: item) {
            msg = item.url.lastPathComponent + "asdfasdf"
            info = try? gpg.info(item.url.path)
            // await fetchDetails(for: item)
            detail = nil
            detail = try? gpg.decrypt(item.url.path)
        }
        .onAppear(perform: loadGpgInfoAndDecrypt)
    }

    private func loadGpgInfoAndDecrypt() {
        // info = try? gpg.info(url.path)
        // detail = try? gpg.decrypt(url.path)
    }
}
