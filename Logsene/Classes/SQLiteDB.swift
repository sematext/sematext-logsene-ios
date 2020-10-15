import Foundation
import SQLite3

struct DBLogEntry {
    let id: Int32
    let data: NSString
}

extension DBLogEntry: SQLTable {
    static var createStatement: String {
        return """
            CREATE TABLE LogEntry(
                Id INTEGER PRIMARY KEY AUTOINCREMENT,
                Data TEXT NOT NULL
            );
        """
    }
}

protocol SQLTable {
    static var createStatement: String { get }
}

enum SQLiteError: Error {
    case OpenDatabase(message: String)
    case Prepare(message: String)
    case Step(message: String)
    case Bind(message: String)
}

class SQLiteDB {
    private let dbPointer: OpaquePointer?
  
    static func open(path: String) throws -> SQLiteDB {
        var db: OpaquePointer?
        if sqlite3_open(path, &db) == SQLITE_OK {
            return SQLiteDB(dbPointer: db)
        } else {
            defer {
                if db != nil {
                    sqlite3_close(db)
                }
            }
            
            if let errorPointer = sqlite3_errmsg(db) {
                let message = String(cString: errorPointer)
                throw SQLiteError.OpenDatabase(message: message)
            } else {
                throw SQLiteError.OpenDatabase(message: "No error message returned")
            }
        }
    }
    
    private init(dbPointer: OpaquePointer?) {
        self.dbPointer = dbPointer
    }
  
    deinit {
        sqlite3_close(dbPointer)
    }
    
    func insertLogEntry(logEntry: DBLogEntry) throws {
        let insertSql = "INSERT INTO LogEntry (Data) VALUES (?);"
        let insertStatement = try prepareStatement(sql: insertSql)
        
        defer {
            sqlite3_finalize(insertStatement)
        }
        
        let data: NSString = logEntry.data
        guard
            sqlite3_bind_text(insertStatement, 1, data.utf8String, -1, nil) == SQLITE_OK
            else {
                throw SQLiteError.Bind(message: errorMessage)
            }
        
        guard sqlite3_step(insertStatement) == SQLITE_DONE else {
            throw SQLiteError.Step(message: errorMessage)
        }
        
        NSLog("Successfully inserted LogEntry row")
    }
    
    func countEntries() throws -> Int {
        let querySql = "SELECT count(*) from LogEntry;"
        let queryStatement = try prepareStatement(sql: querySql)
        
        defer {
            sqlite3_finalize(queryStatement)
        }
        
        guard sqlite3_step(queryStatement) == SQLITE_ROW else {
            return 0
        }
        
        return Int(sqlite3_column_int(queryStatement, 0))
    }
    
    func tableExists() throws -> Bool {
        let querySql = "SELECT name FROM sqlite_master WHERE type='table' AND name='LogEntry';"
        let queryStatement = try prepareStatement(sql: querySql)
        
        defer {
            sqlite3_finalize(queryStatement)
        }
        
        if sqlite3_step(queryStatement) == SQLITE_ROW {
            return true
        }
        
        return false
    }
    
    func fetchTopN(count: Int) throws -> [JsonObject] {
        let querySql = "SELECT * FROM LogEntry ORDER BY `id` DESC LIMIT ?;"
        let queryStatement = try prepareStatement(sql: querySql)
        
        defer {
            sqlite3_finalize(queryStatement)
        }
        
        guard sqlite3_bind_int(queryStatement, 1, Int32(count)) == SQLITE_OK
        else {
            throw SQLiteError.Bind(message: errorMessage)
        }
        
        var results = [JsonObject]()
        var continueGathering = true
        
        repeat {
            if sqlite3_step(queryStatement) == SQLITE_ROW {
                let textData = String(cString: sqlite3_column_text(queryStatement, 1))
                if let obj = try JSONSerialization.jsonObject(with: textData.data(using: String.Encoding.utf8)!, options: JSONSerialization.ReadingOptions()) as? JsonObject {
                    results.append(obj)
                } else {
                    NSLog("Data in database is not a JsonObject, skipping!")
                }
            } else {
                continueGathering = false
            }
        } while continueGathering
        
        guard sqlite3_step(queryStatement) == SQLITE_ROW else {
            return results
        }
        
        return results
    }
    
    func deleteTopN(count: Int) throws {
        let deleteSql = "DELETE FROM LogEntry WHERE `id` IN (SELECT `id` FROM LogEntry ORDER BY `id` ASC limit ?)"
        let deleteStatement = try prepareStatement(sql: deleteSql)
        
        defer {
            sqlite3_finalize(deleteStatement)
        }
        
        guard sqlite3_bind_int(deleteStatement, 1, Int32(count)) == SQLITE_OK
        else {
            throw SQLiteError.Bind(message: errorMessage)
        }
        
        guard sqlite3_step(deleteStatement) == SQLITE_DONE else {
            throw SQLiteError.Step(message: errorMessage)
        }
        
        NSLog("Successfully deleted \(count) rows")
    }
    
    fileprivate var errorMessage: String {
        if let errorPointer = sqlite3_errmsg(dbPointer) {
            let errorMessage = String(cString: errorPointer)
            return errorMessage
        } else {
            return "No error message provided from sqlite"
        }
    }
}

extension SQLiteDB {
    func prepareStatement(sql: String) throws -> OpaquePointer? {
        var statement: OpaquePointer?
        
        guard sqlite3_prepare_v2(dbPointer, sql, -1, &statement, nil) == SQLITE_OK else {
            throw SQLiteError.Prepare(message: errorMessage)
        }
        
        return statement
    }
}

extension SQLiteDB {
    func createTable(table: SQLTable.Type) throws {
        let createTableStatement = try prepareStatement(sql: table.createStatement)
        
        defer {
            sqlite3_finalize(createTableStatement)
        }
        
        guard sqlite3_step(createTableStatement) == SQLITE_DONE else {
            throw SQLiteError.Step(message: errorMessage)
        }
        
        NSLog("\(table) table created")
  }
}
