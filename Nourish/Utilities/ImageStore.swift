import UIKit

enum ImageStore {
    static func saveImage(_ image: UIImage) throws -> String {
        let fileName = "\(UUID().uuidString).jpg"
        let url = try imageURL(fileName: fileName)
        guard let data = image.jpegData(compressionQuality: 0.82) else {
            throw ImageStoreError.encodingFailed
        }
        try data.write(to: url, options: [.atomic])
        return fileName
    }

    static func loadImage(fileName: String) -> UIImage? {
        guard let url = try? imageURL(fileName: fileName) else { return nil }
        return UIImage(contentsOfFile: url.path)
    }

    static func deleteImage(fileName: String?) {
        guard let fileName, let url = try? imageURL(fileName: fileName) else { return }
        try? FileManager.default.removeItem(at: url)
    }

    static func deleteAllImages() {
        guard let directory = try? imageDirectoryURL() else { return }
        try? FileManager.default.removeItem(at: directory)
    }

    private static func imageURL(fileName: String) throws -> URL {
        let directory = try imageDirectoryURL()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory.appending(path: fileName)
    }

    private static func imageDirectoryURL() throws -> URL {
        try FileManager.default.url(
            for: .documentDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        ).appending(path: "MealPhotos", directoryHint: .isDirectory)
    }
}

enum ImageStoreError: Error {
    case encodingFailed
}
