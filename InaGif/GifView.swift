import Foundation

struct Gif: Identifiable {
    let id: String
    let gifUrl: String // URL for the GIF file (tinygif)
    let webmUrl: String? // Optional URL for the WebM file (tinywebm)

    // Function to create a Gif object from a dictionary
    static func fromDictionary(_ dict: [String: AnyObject]) -> Gif? {
        guard let id = dict["id"] as? String,
              let mediaFormats = dict["media_formats"] as? [String: AnyObject] else {
            return nil
        }

        // Extract the tinygif format
        guard let tinyGif = mediaFormats["tinygif"] as? [String: AnyObject],
              let gifUrl = tinyGif["url"] as? String else {
            return nil
        }

        // Optionally extract the tinywebm format
        let webmUrl = (mediaFormats["tinywebm"] as? [String: AnyObject])?["url"] as? String

        return Gif(id: id, gifUrl: gifUrl, webmUrl: webmUrl)
    }
}

