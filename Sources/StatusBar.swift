import SwiftUI

struct StatusBar: View {
    let gpg: Result<(Gpg, Result<Version, any Error>), any Error>

    var body: some View {
        HStack {
            switch gpg {
                case .success(let gpg):
                    Text(URL(fileURLWithPath: gpg.0.execPath).lastPathComponent)
                        .tooltip(gpg.0.execPath)
                    Spacer()
                    switch gpg.1 {
                        case .success(let version):
                            Text(version.number).tooltip(version.info)
                        case .failure(let error):
                            Text("gpg version: \(error)").foregroundStyle(.orange)
                    }
                case .failure(let error):
                    Text("gpg program not found: \(error)").foregroundStyle(.orange)
                    Spacer()
            }
        }
        .foregroundStyle(.primary)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color.indigo.opacity(0.3))
    }
}
