import Foundation
import SQLite

private let tableName = "objects"

/**
 Buffers documents to sqlite database with a fixed size.
 */
class SqliteObjectBuffer {
    let db: Connection
    let objects = Table(tableName)
    let id = Expression<Int64>("id")
    let data = Expression<String?>("data")
    let size: Int
    var _count: Int?

    /**
        Returns the number of objects in the buffer.
    */
    var count: Int {
        get {
            if _count == nil {
                _count = try? db.scalar(objects.count)
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
        db = try Connection(filePath)
        try db.run(objects.create(ifNotExists: true) { t in
            t.column(id, primaryKey: true)
            t.column(data)
        })
    }

    /**
        Adds another json object to the buffer.
    */
    func add(_ obj: JsonObject) throws {
        try db.run(objects.insert(data <- String(jsonObject: obj)!))
        _count? += 1
        if count > size {
            try self.remove(1)
        }
    }

    /**
        Reads up to `max` objects from the buffer in FIFO order.
    */
    func peek(_ max: Int) throws -> [JsonObject] {
        let query = objects.order(id.asc).limit(max)
        var results: [JsonObject] = []
        for record in try db.prepare(query) {
            let jsonString = record[data]!
            if let obj = try JSONSerialization.jsonObject(with: jsonString.data(using: String.Encoding.utf8)!, options: JSONSerialization.ReadingOptions()) as? JsonObject {
                results.append(obj)
            } else {
                NSLog("Data in database is not a JsonObject!")
            }
        }
        return results
    }

    /**
        Removes up to `max` oldest objects.
    */
    func remove(_ max: Int) throws {
        try db.execute("DELETE FROM \(tableName) WHERE `id` IN (SELECT `id` FROM \(tableName) ORDER BY `id` ASC limit \(max));")
        _count? -= db.changes
    }
}
