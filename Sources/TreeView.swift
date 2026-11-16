import SwiftUI

struct TreeView<Data: RandomAccessCollection, ID: Hashable, Content: View>: View
where ID == Data.Element.ID, Data.Element: Identifiable {
    let data: Data
    let keyPath: KeyPath<Data.Element, Data?>
    @ViewBuilder let content: (Data.Element) -> Content

    @State var isExpanded: Bool = true

    init<DataElement>(
        _ data: Data, children: KeyPath<Data.Element, Data?>,
        @ViewBuilder content: @escaping (DataElement) -> Content
    ) where DataElement: Identifiable, DataElement == Data.Element {
        self.data = data
        self.keyPath = children
        self.content = content
    }

    var body: some View {
        ForEach(data) { elem in
            if let c = elem[keyPath: keyPath] {
                DisclosureGroup(isExpanded: $isExpanded) {
                    TreeView(c, children: keyPath, content: content)
                } label: {
                    content(elem)
                }
            } else {
                content(elem)
            }
        }
    }
}
