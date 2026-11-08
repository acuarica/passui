import SwiftUI

struct StatusBar: View {
    let left: String
    let right: String
    var body: some View {
            HStack(spacing: 8) {
                Text(left)
                    // .lineLimit(1)
                // Spacer(minLength: 0)
                Spacer()
                Text(right)
                    // .lineLimit(1)
                    // .truncationMode(.middle)
                    // .help()
            }
            .font(.caption2)
            .foregroundStyle(.primary)
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            // .frame(maxWidth: .infinity)
            .background(Color.indigo)
    }
}