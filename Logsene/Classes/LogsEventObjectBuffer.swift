import Foundation

/**
 Buffers documents to local database with a fixed size.
 */
class LogsEventObjectBuffer {
    let size: Int
    let db: SQLiteDB
    var _count: Int?
    
    /**
        Returns the number of objects in the buffer.
    */
    var count: Int {
        get {
            if _count == nil {
                // TODO: retrieve count from DB
            }
            return _count ?? 0
        }
        set {
            _count = newValue
        }
    }

    /**
        Initializer.

        - Parameters:
            - filePath: Path to the database.
            - size: Max size of the buffer (older messages will be discarded).
    */
    init(filePath: String, size: Int) throws {
        self.size = size
        self.db = try SQLiteDB.open(path: filePath)
        // TODO: check if the DB table is already there
        var tablePresent = true
        if !tablePresent {
            try db.createTable(table: DBLogEntry.self)
        }
    }

    /**
        Adds another json object to the buffer.
    */
    func add(_ obj: JsonObject) throws {
        let data = String(jsonObject: obj)!
        try db.insertLogEntry(logEntry: DBLogEntry(id: 1, data: data as NSString))
        _count? += 1
        if count > size {
            try self.remove(1)
        }
    }

    /**
        Reads up to `max` objects from the buffer in FIFO order.
    */
    func peek(_ max: Int) -> [JsonObject]? {
        return [JsonObject]()
    }
    
    func countEntries() -> Int {
        // TODO implement
        return 0
    }

    /**
        Removes up to `max` oldest objects.
    */
    func remove(_ max: Int) throws {
        try db.deleteTopN(count: max)
        _count? = countEntries()
    }
}
