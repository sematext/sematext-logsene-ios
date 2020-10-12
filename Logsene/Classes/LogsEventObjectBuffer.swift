import Foundation

/**
 Buffers documents to local database with a fixed size.
 */
class LogsEventObjectBuffer {
    let size: Int
    var docs: Queue<JsonObject>
    var syncFileSync: Bool
    var fileUrl: URL

    /**
        Returns the number of objects in the buffer.
    */
    var count: Int {
        return docs.count
    }

    /**
        Initializer.

        - Parameters:
            - filePath: Path to the database.
            - size: Max size of the buffer (older messages will be discarded).
            - syncFileSync: Should buffer file be synced.
    */
    init(filePath: String, size: Int, syncFileSync: Bool) throws {
        self.size = size
        self.docs = Queue<JsonObject>()
        self.syncFileSync = syncFileSync
        self.fileUrl = URL(fileURLWithPath: filePath)
        self.readFile()
    }

    /**
        Adds another json object to the buffer.
    */
    func add(_ obj: JsonObject) {
        if docs.count > size {
            let above = size - docs.count
            self.remove(above)
        }
        docs.enqueue(obj)
        if self.syncFileSync {
            self.writeFile()
        }
    }

    /**
        Reads up to `max` objects from the buffer in FIFO order.
    */
    func peek(_ max: Int) -> [JsonObject]? {
        return docs.peekN(max)
    }

    /**
        Removes up to `max` oldest objects.
    */
    func remove(_ max: Int) {
        for _ in 1...max {
           _ = docs.dequeue()
        }
        if self.syncFileSync {
            self.writeFile()
        }
    }
    
    func writeFile() {
        if !docs.isEmpty {
            if let outputStream = OutputStream(url: self.fileUrl, append: false) {
                outputStream.open()
                for index in 1...docs.count {
                    let stringDoc = String(jsonObject: docs.peekAt(index))!
                    let numWritten = outputStream.write(stringDoc, maxLength: stringDoc.count)
                    if numWritten < stringDoc.count {
                        NSLog("Expected to write more bytes")
                    }
                }
                outputStream.close()
            } else {
                NSLog("Unable to write file")
            }
        }
    }
    
    func readFile() {
        try? String(contentsOf: self.fileUrl, encoding: .utf8)
            .split(separator: "\n")
            .forEach({ (line) in
                if let obj = try JSONSerialization.jsonObject(with: line.data(using: String.Encoding.utf8)!, options: JSONSerialization.ReadingOptions()) as? JsonObject {
                    docs.enqueue(obj)
                } else {
                    NSLog("Data in file is not a JSONObject!")
                }
            })
    }
    
    func forceClose() {
        self.writeFile()
    }
}
