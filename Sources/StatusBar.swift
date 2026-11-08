import SwiftUI

struct StatusBar: View {
    let left: String
    let right: String
    var body: some View {
        HStack(spacing: 8) {
            Text(left)
                .tooltip {
                    VStack {
                        HStack {
                            Text("asdfasdf")
                            Text("123324")
                        }
                        Text("ljkjkljlk")
                        Text("zxcx")
                        Text("qweweqqew")
                        Text("123324")
                    }
                }
            Spacer()
            Text(right)
                .tooltip {
                    VStack {
                        Text("asdfasdf")
                        Text("123123233")
                        Text("tre")
                    }
                }
            Divider()
                .frame(height: 14)
                .padding(.leading, 6)
                .padding(.trailing, 6)
            Button("Quit", systemImage: "xmark.rectangle") {
                NSApplication.shared.terminate(nil)
            }
        }
        .font(.caption2)
        .foregroundStyle(.primary)
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(Color.indigo.opacity(0.4))
    }
}
