import Foundation

// Structure representing directory
internal struct Directory {
    let url: URL

    init(withDirectoryPath path: String) throws {
        self.url = try createCachesDirectoryIfNotExists(directoryPath: path)
    }

    // Creates new appen only file
    func createFile(named fileName: String) throws -> File {
        let fileURL = url.appendingPathComponent(fileName, isDirectory: false)
        guard FileManager.default.createFile(atPath: fileURL.path, contents: nil, attributes: nil) == true else {
            throw SematextLogsError.runtimeError("Cannot create file \(fileURL.path)")
        }
        return File(url: fileURL)
    }

    // Lists files from the directory
    func listFiles() throws -> [File] {
        return try FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: [.isRegularFileKey, .canonicalPathKey]).map { url in File(url: url) }
    }
}

// Creates directory for log files in the /Library/Caches system directory
private func createCachesDirectoryIfNotExists(directoryPath: String) throws -> URL {
    guard let cachesDirectoryURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first else {
        throw SematextLogsError.runtimeError("Cannot get /Library/Caches/")
    }
    let directoryURL = cachesDirectoryURL.appendingPathComponent(directoryPath, isDirectory: true)
    
    do {
        try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true, attributes: nil)
    } catch {
        throw SematextLogsError.runtimeError("Cannot create directory in /Library/Caches/")
    }
    
    return directoryURL
}
