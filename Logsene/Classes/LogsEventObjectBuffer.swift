import Foundation

/**
 Buffers documents to local database with a fixed size.
 */
class LogsEventObjectBuffer {
    let size: Int
    
    /**
        Returns the number of objects in the buffer.
    */
    var count: Int {
        return 0
    }

    /**
        Initializer.

        - Parameters:
            - filePath: Path to the database.
            - size: Max size of the buffer (older messages will be discarded).
    */
    init(filePath: String, size: Int) throws {
        self.size = size
    }

    /**
        Adds another json object to the buffer.
    */
    func add(_ obj: JsonObject) {
        
    }

    /**
        Reads up to `max` objects from the buffer in FIFO order.
    */
    func peek(_ max: Int) -> [JsonObject]? {
        return [JsonObject]()
    }

    /**
        Removes up to `max` oldest objects.
    */
    func remove(_ max: Int) {
        
    }
}
