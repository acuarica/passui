import SwiftUI

struct StatusBar: View {
    let left: String
    let right: String
    var body: some View {
            HStack(spacing: 8) {
                Text(left)
            .tooltip {
                HStack{
                Text("asdfasdf")
                Text("123324")
                Text("123324")
                }
            }

                    // .lineLimit(1)
                // Spacer(minLength: 0)
                Spacer()
                Text(right)
            .tooltip {
                Text("asdfasdf")
                Text("asdfasdf")
                Text("asdfasdf")
            }
                    // .lineLimit(1)
                    // .truncationMode(.middle)
                    // .help()
                    // Button()
                    Divider()
                    .frame(height: 14)
                    .padding(.leading, 6)
                    .padding(.trailing, 6)
            // .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                Button("Quit", systemImage: "xmark.rectangle") {
                    NSApplication.shared.terminate(nil)
                }
                // .buttonStyle(.borderless)
                // .padding(.leading, 20)
            }
            .font(.caption2)
            .foregroundStyle(.primary)
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            // .frame(maxWidth: .infinity)
            .background(Color.indigo.opacity(0.4))
    }
}