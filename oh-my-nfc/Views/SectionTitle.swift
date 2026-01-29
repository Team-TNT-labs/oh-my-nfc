import SwiftUI

struct SectionTitle: View {
    let title: String

    init(_ title: String) {
        self.title = title
    }

    var body: some View {
        Text(title)
            .font(.title2.weight(.bold))
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}
