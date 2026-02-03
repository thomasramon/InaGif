import SwiftUI
import SDWebImageSwiftUI

struct ContentView: View {
    @ObservedObject var viewModel: ContentViewModel
    let openPreferences: () -> Void
    let toggleGifOption: () -> Void

    var body: some View {
        VStack(spacing: 10) {
            Button("InaGif") {
                openPreferences()
            }
            .font(.headline)
            .padding(.top, 5)

            Button("Toggle Layout (\(viewModel.isCompactLayout ? "Narrow View" : "Wide View"))") {
                toggleGifOption()
            }
            .font(.subheadline)
            .padding(.top, 5)

            TextField("Search for GIFs", text: $viewModel.searchTerm, onCommit: performSearch)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal, 15)

            Button("Search") {
                performSearch()
            }
            .padding(.top, 5)

            // Display recent searches, evenly spaced across the window
            if !viewModel.recentSearches.isEmpty {
                VStack(alignment: .leading) {
                    Text("Recent Searches:")
                        .font(.subheadline)
                        .padding(.leading)

                    HStack {
                        // Evenly distribute recent searches with Spacer
                        ForEach(viewModel.recentSearches.prefix(5), id: \.self) { search in
                            Button(search) {
                                viewModel.searchTerm = search
                                performSearch()
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(8)

                            Spacer() // Add space between the buttons
                        }
                    }
                    .padding(.horizontal, 15) // Adjust padding to align with the window edges
                }
                .padding(.bottom, 10)
            }

            if viewModel.isLoading {
                ProgressView("Loading...")
                    .padding()
            } else if let errorMessage = viewModel.errorMessage {
                Text("Error: \(errorMessage)")
                    .foregroundColor(.red)
                    .padding()
            } else {
                ScrollView {
                    LazyVGrid(columns: layoutColumns) {
                        ForEach(viewModel.gifs, id: \.id) { gif in
                            GifView(gif: gif, onCopy: {
                                copyGifToClipboard(url: gif.gifUrl)
                            })
                        }
                    }
                    .padding([.horizontal, .bottom])
                }
            }

            if viewModel.showCopiedMessage, let copiedGifMessage = viewModel.copiedGifMessage {
                Text(copiedGifMessage)
                    .foregroundColor(.green)
                    .padding()
                    .transition(.opacity)
                    .opacity(viewModel.showCopiedMessage ? 1 : 0)
            }
        }
        .frame(width: windowWidth, height: windowHeight)
    }

    private var layoutColumns: [GridItem] {
        return Array(repeating: GridItem(.flexible()), count: viewModel.isCompactLayout ? 5 : 2)
    }

    private var windowWidth: CGFloat {
        return viewModel.isCompactLayout ? 600 : 300
    }

    private var windowHeight: CGFloat {
        return viewModel.isCompactLayout ? 400 : 600
    }

    // Perform the search and add it to recent searches
    func performSearch() {
        guard !viewModel.searchTerm.isEmpty else {
            viewModel.errorMessage = "Please enter a search term."
            return
        }

        addRecentSearch(viewModel.searchTerm)
        requestData()
    }

    // Add the search term to recent searches, ensure the limit is 5 and remove the oldest (rightmost)
    private func addRecentSearch(_ term: String) {
        var searches = viewModel.recentSearches
        if !searches.contains(term) {
            if searches.count >= 5 { // Keep a maximum of 5 searches
                searches.removeFirst() // Remove the oldest (rightmost) search
            }
            searches.append(term) // Add the new search (most recent)
        }
        viewModel.recentSearchesString = searches.joined(separator: ",")
    }

    func requestData() {
        viewModel.isLoading = true
        viewModel.errorMessage = nil

        let apikey = "AIzaSyBcjVKGQiOoNDE0FTfmr1PEoR7Ic6rLO7I" // Replace with your actual API key
        let clientkey = "my_test_app"
        let limit = 36

        guard let searchURL = URL(string: "https://tenor.googleapis.com/v2/search?q=\(viewModel.searchTerm)&key=\(apikey)&client_key=\(clientkey)&limit=\(limit)") else {
            viewModel.errorMessage = "Invalid URL"
            viewModel.isLoading = false
            return
        }

        let searchRequest = URLRequest(url: searchURL)
        makeWebRequest(urlRequest: searchRequest) { response in
            DispatchQueue.main.async {
                viewModel.isLoading = false

                if let response = response, let results = response["results"] as? [[String: AnyObject]] {
                    viewModel.gifs = results.compactMap { Gif.fromDictionary($0) }
                    if viewModel.gifs.isEmpty {
                        viewModel.errorMessage = "No GIFs found."
                    }
                } else {
                    viewModel.errorMessage = "No GIFs found or invalid response."
                }
            }
        }
    }

    func makeWebRequest(urlRequest: URLRequest, callback: @escaping ([String: AnyObject]?) -> ()) {
        let task = URLSession.shared.dataTask(with: urlRequest) { (data, response, error) in
            if let error = error {
                callback(nil)
                return
            }

            guard let data = data else {
                callback(nil)
                return
            }

            do {
                if let jsonResult = try JSONSerialization.jsonObject(with: data, options: []) as? [String: AnyObject] {
                    callback(jsonResult)
                } else {
                    callback(nil)
                }
            } catch {
                callback(nil)
            }
        }
        task.resume()
    }

    func copyGifToClipboard(url: String) {
        guard let gifUrl = URL(string: url) else { return }

        let task = URLSession.shared.dataTask(with: gifUrl) { data, response, error in
            guard let data = data, error == nil else {
                DispatchQueue.main.async {
                    viewModel.copiedGifMessage = "Failed to copy GIF."
                    viewModel.showCopiedMessage = true
                    fadeOutCopiedMessage()
                }
                return
            }

            DispatchQueue.main.async {
                let pasteboard = NSPasteboard.general
                pasteboard.clearContents()

                let tempDirectory = FileManager.default.temporaryDirectory
                let tempFileURL = tempDirectory.appendingPathComponent(UUID().uuidString).appendingPathExtension("gif")

                do {
                    try data.write(to: tempFileURL)
                    pasteboard.declareTypes([.fileURL], owner: nil)
                    pasteboard.setData(tempFileURL.dataRepresentation, forType: .fileURL)

                    viewModel.copiedGifMessage = "GIF copied to clipboard!"
                    viewModel.showCopiedMessage = true
                    fadeOutCopiedMessage()
                } catch {
                    viewModel.copiedGifMessage = "Failed to copy GIF."
                    viewModel.showCopiedMessage = true
                    fadeOutCopiedMessage()
                }
            }
        }
        task.resume()
    }

    func fadeOutCopiedMessage() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation(.easeInOut(duration: 1.0)) {
                viewModel.showCopiedMessage = false
            }
        }
    }
}
