import SwiftUI
import AppKit

class ContentViewModel: ObservableObject {
    @Published var searchTerm: String = ""
    @Published var gifs: [Gif] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var copiedGifMessage: String?
    @Published var showCopiedMessage: Bool = false

    @AppStorage("isCompactLayout") var isCompactLayout = false
    @AppStorage("recentSearches") var recentSearchesString: String = ""

    func resetState() {
        searchTerm = ""
        gifs.removeAll()
        isLoading = false
        errorMessage = nil
        copiedGifMessage = nil
        showCopiedMessage = false
        // Do not reset recentSearchesString to keep it persistent.
    }

    // Split the stored recent searches into an array of strings
    var recentSearches: [String] {
        return recentSearchesString.components(separatedBy: ",").filter { !$0.isEmpty }
    }
}