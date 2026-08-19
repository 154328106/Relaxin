import SwiftUI
import UIKit

/// Top-level ShareSheet (UIActivityViewController wrapper) usable from any
/// view. GlassSubPageContent uses it to present Export Logs / Software
/// License URLs after a row tap.
struct GlassSharePresentation: Identifiable {
    let url: URL
    var id: URL { url }
}

struct GlassShareSheet: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context _: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: [url], applicationActivities: nil)
    }

    func updateUIViewController(_: UIActivityViewController, context _: Context) {}
}
