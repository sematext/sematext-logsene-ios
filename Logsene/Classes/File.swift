import Foundation

// Structure representing an append only file.
internal struct File {
    let url: URL
    let name: String

    init(url: URL) {
        self.url = url
        self.name = url.lastPathComponent
    }

    // Appends data to a file
    func append(data: String) throws {
        let fileHandle = try FileHandle(forWritingTo: url)
        #if compiler(>=5.2)
        if #available(iOS 13.4, macOS 10.15.4, tvOS 13.4, watchOS 6.2, *) {
            defer {
                try? fileHandle.close()
            }
            try fileHandle.seekToEnd()
            try fileHandle.write(contentsOf: data.data(using: String.Encoding.utf8)!)
        } else {
            try appendPre134(data, to: fileHandle)
        }
        #else
            try appendPre134(data, to: fileHandle)
        #endif
    }

    // Appends data to a file on older operating systems
    private func appendPre134(_ data: String, to fileHandle: FileHandle) throws {
        defer {
            fileHandle.closeFile()
        }
        fileHandle.seekToEndOfFile()
        fileHandle.write(data.data(using: String.Encoding.utf8)!)
    }

    // Reads data from a file
    func read() throws -> Data {
        let fileHandle = try FileHandle(forReadingFrom: url)
        #if compiler(>=5.2)
        if #available(iOS 13.4, macOS 10.15.4, tvOS 13.4, watchOS 6.2, *) {
            defer {
                try? fileHandle.close()
            }
            return try fileHandle.readToEnd() ?? Data()
        } else {
            return try readPre134(from: fileHandle)
        }
        #else
            return try readPre134(from: fileHandle)
        #endif
    }
    
    // Reads data from a file on older operating systems
    private func readPre134(from fileHandle: FileHandle) throws -> Data {
        let data = fileHandle.readDataToEndOfFile()
        fileHandle.closeFile()
        return data
    }
    
    // Returns the size of the file
    func size() -> UInt64 {
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
            return attributes[.size] as? UInt64 ?? 0
        } catch {
            NSLog("Error reading current log file size")
        }
        return 0
    }

    // Deletes file
    func delete() throws {
        try FileManager.default.removeItem(at: url)
    }
}
