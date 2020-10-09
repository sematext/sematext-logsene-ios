import Foundation

/**
 Buffers documents to local database with a fixed size.
 */
class LogsEventObjectBuffer {
    let size: Int
    var docs: Queue<JsonObject>

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
    */
    init(filePath: String, size: Int) throws {
        self.size = size
        self.docs = Queue<JsonObject>()
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
    }
}
