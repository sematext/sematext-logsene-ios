import Foundation

// Structure representing logs file storage
class FileStorage {
    let filePrefix: String = "sematext_logs_sdk"
    let documentSeparator: String = "###___SCLogsMobile###"
    let logsFilePath: String
    let maxFileSize: Int
    let maxNumberOfFiles: Int
    var currentlyUsedFileName: String = ""
    var currentLogsFile: File?
    var logsDirectory: Directory
    
    init(logsFilePath: String, maxFileSize: Int, maxNumberOfFiles: Int) throws {
        self.logsFilePath = logsFilePath
        self.maxFileSize = maxFileSize
        self.maxNumberOfFiles = maxNumberOfFiles
        self.logsDirectory = try Directory(withDirectoryPath: "sematextLogs")
        try openNewLogsFile()
    }
    
    // Retrieves log objects from a file
    func getObjectsFromFile(file: File) -> [JsonObject]? {
        do {
            let data = try file.read()
            let stringData = String(decoding: data, as: UTF8.self)
            let lines = stringData.components(separatedBy: documentSeparator)
            var documents: [JsonObject] = []
            try lines.forEach { line in
                if !line.isEmpty {
                    if let jsonObject = try JSONSerialization.jsonObject(with: line.data(using: String.Encoding.utf8)!, options: JSONSerialization.ReadingOptions()) as? JsonObject {
                        documents.append(jsonObject)
                    }
                }
            }
            return documents
        } catch {
            #if DEBUG
            NSLog("Error reading data from file \(file.name)")
            #endif
        }
        return nil
    }
    
    // Adds new log event to currently opened file
    func add(_ obj: JsonObject) throws {
        let data = String(jsonObject: obj)!
        try writeDataToCurrentFile(data)
        if getCurrentlyUsedFileSize() > maxFileSize {
            rollFile()
        }
    }
    
    // Rolls file creating new one
    func rollFile() {
        do {
            try openNewLogsFile()
        } catch {
        }
    }
    
    // Returns if there is data available for sending
    func hasDataForSending() -> Bool {
        do {
            return try self.logsDirectory.listFiles().count > 0
        } catch {
            return false
        }
    }
    
    // Checks if the file is currently used
    func isFileCurrentlyUsed(file: File) -> Bool {
        return self.currentlyUsedFileName == file.name
    }
    
    // Retrieves files from logs directory
    func getFilesInDirectory() throws -> [File] {
        return try self.logsDirectory.listFiles()
    }
    
    // Deletes file
    func deleteFile(file: File) {
        do {
            try file.delete()
        } catch {
            #if DEBUG
            NSLog("Error while deleting file: \(file.name)")
            #endif
        }
    }
    
    // Returns size of the currently used file
    private func getCurrentlyUsedFileSize() -> UInt64 {
        return self.currentLogsFile!.size()
    }
    
    // Cleans up logs data directory deleting files that are not needed
    private func cleanUp() {
        do {
            let files = try self.logsDirectory.listFiles()
            var numFilesToDelete = files.count - maxNumberOfFiles + 1
            if (numFilesToDelete > 0) {
                let sortedFiles = files.sorted { (first, second) -> Bool in
                    first.name == second.name
                }
                for file in sortedFiles {
                    if currentlyUsedFileName != file.name && numFilesToDelete > 0 {
                        numFilesToDelete -= 1
                        deleteFile(file: file)
                    }
                }
            }
        } catch {
            #if DEBUG
            NSLog("Error during files cleanup, skipping")
            #endif
        }
    }
    
    private func writeDataToCurrentFile(_ data: String) throws {
        try self.currentLogsFile!.append(data: "\(data)\(documentSeparator)")
    }
    
    private func openNewLogsFile() throws {
        let newLogsFileName = getNextFileName()
        self.currentlyUsedFileName = newLogsFileName
        self.currentLogsFile = try self.logsDirectory.createFile(named: newLogsFileName)
        cleanUp()
    }
    
    private func getNextFileName() -> String {
        let sinceEpoch = NSDate().timeIntervalSince1970
        return "\(self.filePrefix)_\(sinceEpoch)"
    }
}
