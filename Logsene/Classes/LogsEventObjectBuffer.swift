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
                _count = self.countEntries()
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
        let tablePresent = try db.tableExists()
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
        do {
            return try db.fetchTopN(count: max)
        } catch {
            NSLog("Error while running DB query")
        }
        
        return nil
    }
    
    func countEntries() -> Int {
        do {
            return try db.countEntries()
        } catch {
            NSLog("Error while running DB count query")
        }
        
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
