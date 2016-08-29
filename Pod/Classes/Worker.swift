import Foundation

/**
 Handles uploading of data in batches to Logsene.

 Events queued while offline will be saved to disk and sent later.
 */
class Worker {
    private let maxBatchSize = 50
    private let minBatchSize = 10
    private let timeTriggerSec: UInt64 = 60
    private let preflightBuffer: SqliteObjectBuffer
    private let serialQueue: dispatch_queue_t
    private let timer: dispatch_source_t
    private let client: LogseneClient
    private let type: String
    private let reach: LReachability
    private let isOnline = true

    init(client: LogseneClient, type: String, maxOfflineMessages: Int) throws {
        self.client = client
        self.type = type
        serialQueue = dispatch_queue_create("logworker_events", DISPATCH_QUEUE_SERIAL)
        reach = try LReachability.reachabilityForInternetConnection()

        // Setup sqlite buffer for storing messages before sending them to Logsene
        // This also acts as the offline buffer if device is not online
        let path = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true).first!
        preflightBuffer = try SqliteObjectBuffer(filePath: "\(path)/logsene.sqlite3", size: maxOfflineMessages)

        // creates a timer for sending data every 60s (will tick once right away to send previously buffered data)
        timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, serialQueue)
        dispatch_source_set_timer(timer, DISPATCH_TIME_NOW, timeTriggerSec * NSEC_PER_SEC, 1 * NSEC_PER_SEC);
        dispatch_source_set_event_handler(timer) {
            do {
                try self.handleTimerTick()
            } catch let err {
                NSLog("Error while handling timer tick: \(err)")
            }
        }
        dispatch_resume(timer)

        // Setup Reachability to notify when device is online/offline
        reach.whenReachable = { (reach) in
            dispatch_async(self.serialQueue) {
                self.isOnline = true
            }
        }
        reach.whenUnreachable = { (reach) in
            dispatch_async(self.serialQueue) {
                self.isOnline = false
            }
        }
        try reach.startNotifier()
    }

    func addToQueue(event: JsonObject) {
        dispatch_async(serialQueue) {
            do {
                try self.handleNewEvent(event)
            } catch let err {
                NSLog("Error while adding to queue: \(err)")
            }
        }
    }

    private func handleNewEvent(event: JsonObject) throws {
        try preflightBuffer.add(event)
        
        if preflightBuffer.count >= minBatchSize && isOnline {
            try sendInBatches()
        }
    }

    private func handleTimerTick() throws {
        if isOnline {
            try sendInBatches()
        }
    }

    /// Invalidates the timer, pushing the next tick by *timeTriggerSec* seconds.
    private func invalidateTimer() {
        let newTime = dispatch_time(DISPATCH_TIME_NOW, Int64(timeTriggerSec * NSEC_PER_SEC))
        dispatch_source_set_timer(timer, newTime, timeTriggerSec * NSEC_PER_SEC, 1 * NSEC_PER_SEC)
    }

    private func sendInBatches() throws {
        while preflightBuffer.count > 0 {
            let batch = try preflightBuffer.peek(maxBatchSize)
            if sendBatch(batch) {
                invalidateTimer()
                try preflightBuffer.remove(batch.count)
            } else {
                return
            }
        }
    }

    private func sendBatch(batch: [JsonObject]) -> Bool {
        var documents: [(source: String, type: String)] = []
        for source in batch {
            documents.append((source: String(jsonObject: source)!, type: type))
        }
        NSLog("Attempting to send bulk data to logsene")
        return attemptExecute(BulkIndex(documents: documents), attempts: 3)
    }

    private func attemptExecute(bulkIndex: BulkIndex, attempts: Int) -> Bool {
        guard attempts > 0 else { return false }

        var success = false
        var online = true
        client.execute(bulkIndex).success { (result) in
            // `errors` can be either boolean (false) or number (eg. 3), so we need to parse that
            if let errors = result["errors"] where NSString(string: "\(errors)").boolValue {
                let response = String(jsonObject: result)!
                NSLog("Unable to index all documents. Got response: \(response)")
            }

            // We set success in any case, as we most likely cannot resolve the issue by sending the same documents again.
            // Possible causes for errors might be invalid json, or invalid mapping.
            success = true
        }.failure { (maybeError, maybeResponse, maybeData) in
            if let error = maybeError {
                if error.code == NSURLErrorNotConnectedToInternet {
                    online = false
                }
                NSLog("Unable to send request: \(error)")
            }
            if let response = maybeResponse {
                NSLog("Non-success status code received from logsene receiver: \(response.statusCode), response:\n\(maybeData)")
            }
        }.wait()

        if !success && online {
            return attemptExecute(bulkIndex, attempts: attempts - 1)
        }

        return success
    }
}
