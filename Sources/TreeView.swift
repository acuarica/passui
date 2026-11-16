import SwiftUI

struct TreeView<Data: RandomAccessCollection, Content: View>: View
where Data.Element: Identifiable {
    private let data: Data
    private let field: KeyPath<Data.Element, Data?>
    private let content: (Data.Element) -> Content

    @State private var isExpanded: Bool = true

    init(
        _ data: Data, children: KeyPath<Data.Element, Data?>,
        content: @escaping (Data.Element) -> Content
    ) {
        self.data = data
        self.field = children
        self.content = content
    }

    var body: some View {
        ForEach(data) { elem in
            if let childrenData = elem[keyPath: field] {
                DisclosureGroup(isExpanded: $isExpanded) {
                    TreeView(childrenData, children: field, content: content)
                } label: {
                    content(elem)
                }
            } else {
                content(elem)
            }
        }
    }
}
