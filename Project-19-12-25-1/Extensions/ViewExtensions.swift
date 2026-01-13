import SwiftUI

extension View {
    func calmingPreview() -> some View {
        self
            .previewDisplayName("Calming Preview")
            .preferredColorScheme(.light)
    }
}

