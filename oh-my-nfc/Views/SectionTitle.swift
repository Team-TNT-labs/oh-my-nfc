import SwiftUI

struct SectionTitle: View {
    let title: String

    init(_ title: String) {
        self.title = title
    }

    var body: some View {
        Text(title)
            .font(.title2.weight(.bold))
            .fontDesign(.rounded)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Adaptive Card Modifier

struct CardStyle: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        content
            .padding(16)
            .background(
                Color(.secondarySystemGroupedBackground),
                in: .rect(cornerRadius: 16)
            )
            .shadow(
                color: colorScheme == .dark ? .clear : .black.opacity(0.06),
                radius: 12, y: 4
            )
            .shadow(
                color: colorScheme == .dark ? .clear : .black.opacity(0.02),
                radius: 2, y: 1
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        colorScheme == .dark
                            ? Color.white.opacity(0.08)
                            : Color.clear,
                        lineWidth: 1
                    )
            )
    }
}

extension View {
    func cardStyle() -> some View {
        modifier(CardStyle())
    }
}
