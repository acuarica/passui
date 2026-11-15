import SwiftUI

struct VaultItemDetail: View {
    let url: URL
    let gpg: Gpg

    @State private var info: String?
    @State private var detail: String?

    var body: some View {
        VStack {
            Text(url.lastPathComponent)
            Divider()
            TabView {
                Group {

                    if let info {
                        Text(info)
                            .textSelection(.enabled)
                    } else {
                        Text("error could not load gpg info")
                    }
                    Divider()
                }.tabItem {
                    Label("Info", systemImage: "info.circle")
                }
                Group {

                    if let detail {
                        Text(detail)
                            .textSelection(.enabled)
                    } else {
                        Text("error could not load gpg detail")
                    }
                    Spacer()
                    Text("")
                }.tabItem {
                    Label("Details", systemImage: "doc.text")
                }
            }
        }
        .padding()
        .onAppear(perform: loadGpgInfoAndDecrypt)
    }

    private func loadGpgInfoAndDecrypt() {
        info = try? gpg.info(url.path)
        detail = try? gpg.decrypt(url.path)
    }
}
