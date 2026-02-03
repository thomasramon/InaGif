import SwiftUI
import SDWebImageSwiftUI
import WebKit

// GifView Definition
struct GifView: View {
    let gif: Gif
    let onCopy: () -> Void

    var body: some View {
        if let gifUrl = URL(string: gif.gifUrl) {
            AnimatedImage(url: gifUrl)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 100, height: 100)
                .cornerRadius(8)
                .onTapGesture {
                    onCopy()  // Trigger the copy action when tapped
                }
        } else if let webmUrl = gif.webmUrl, let webmUrlObj = URL(string: webmUrl) {
            WebView(url: webmUrlObj)
                .frame(width: 100, height: 100)
                .cornerRadius(8)
                .onTapGesture {
                    onCopy()  // Trigger the copy action when tapped
                }
        }
    }
}

// WebView Definition
struct WebView: NSViewRepresentable {
    let url: URL

    func makeNSView(context: Context) -> WKWebView {
        return WKWebView()
    }

    func updateNSView(_ webView: WKWebView, context: Context) {
        let request = URLRequest(url: url)
        webView.load(request)
    }
}


