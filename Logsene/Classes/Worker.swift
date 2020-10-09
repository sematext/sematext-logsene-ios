import Foundation
import CoreLocation

/**
 Handles uploading of data in batches to Logsene.

 Events queued while offline will be saved to disk and sent later.
 */
class Worker: NSObject {
    var locationEnabled: Bool = false
    var locationSet: Bool = false
    var currentLatitude: Double? = 0.0
    var currentLongitude: Double? = 0.0
    
    fileprivate let maxBatchSize = 50
    fileprivate let minBatchSize = 10
    fileprivate let timeTriggerSec = 60
    fileprivate let preflightBuffer: LogsEventObjectBuffer
    fileprivate let serialQueue: DispatchQueue
    fileprivate var timer: DispatchSourceTimer
    fileprivate let client: LogseneClient
    fileprivate let type: String
    fileprivate let reach: Reachability
    fileprivate var isOnline: Bool = true
    fileprivate var isActive: Bool = true
    fileprivate var locationManager: CLLocationManager? = nil
    
    init(client: LogseneClient, type: String, maxOfflineMessages: Int, automaticLocationEnriching: Bool, useLocationOnlyInForeground: Bool) throws {
        serialQueue = DispatchQueue(label: "logworker_events", attributes: [])
        reach = Reachability()!

        // Setup sqlite buffer for storing messages before sending them to Logsene
        // This also acts as the offline buffer if device is not online
        let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
        preflightBuffer = try LogsEventObjectBuffer(filePath: "\(path)/logsene.sqlite3", size: maxOfflineMessages)

        self.client = client
        self.type = type
        
        // creates a timer for sending data every 60s (will tick once right away to send previously buffered data)
        timer = DispatchSource.makeTimerSource(queue: serialQueue)
        timer.schedule(deadline: .now(), repeating: .seconds(timeTriggerSec), leeway: .seconds(1))
        
        // initialize NSObject
        super.init()
        
        // setup location manager if needed - this should be done only for iOS
        #if os(macOS)
        #else
        if automaticLocationEnriching {
            self.locationManager = CLLocationManager()
            self.locationManager?.delegate = self
            self.locationEnabled = true
            if useLocationOnlyInForeground {
                self.locationManager?.requestWhenInUseAuthorization()
            } else {
                self.locationManager?.requestAlwaysAuthorization()
            }
            self.readInitialLocation()
        }
        #endif
        
        // setup the timer
        timer.setEventHandler {
            do {
                try self.handleTimerTick()
            } catch let err {
                NSLog("Error while handling timer tick: \(err)")
            }
        }
        timer.resume()

        // Setup Reachability to notify when device is online/offline
        reach.whenReachable = { (reach) in
            self.serialQueue.async {
                self.isOnline = true
            }
        }
        reach.whenUnreachable = { (reach) in
            self.serialQueue.async {
                self.isOnline = false
            }
        }
        
        try reach.startNotifier()
    }

    func addToQueue(_ event: JsonObject) {
        serialQueue.async {
            do {
                try self.handleNewEvent(event)
            } catch let err {
                NSLog("Error while adding to queue: \(err)")
            }
        }
    }
    
    func resume() {
        self.isActive = true
    }
    
    func pause() {
        self.isActive = false
    }

    fileprivate func handleNewEvent(_ event: JsonObject) throws {
        try preflightBuffer.add(event)
        
        if preflightBuffer.count >= minBatchSize && isOnline && isActive {
            try sendInBatches()
        }
    }

    fileprivate func handleTimerTick() throws {
        if isOnline && isActive {
            try sendInBatches()
        }
    }

    /// Invalidates the timer, pushing the next tick by *timeTriggerSec* seconds.
    fileprivate func invalidateTimer() {
        timer.schedule(deadline: .now() + .seconds(timeTriggerSec), repeating: .seconds(timeTriggerSec), leeway: .seconds(1))
    }

    fileprivate func sendInBatches() throws {
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

    fileprivate func sendBatch(_ batch: [JsonObject]) -> Bool {
        var documents: [(source: String, type: String)] = []
        for source in batch {
            documents.append((source: String(jsonObject: source)!, type: type))
        }
        NSLog("Attempting to send bulk data to logsene")
        return attemptExecute(BulkIndex(documents: documents), attempts: 3)
    }

    fileprivate func attemptExecute(_ bulkIndex: BulkIndex, attempts: Int) -> Bool {
        guard attempts > 0 else { return false }

        var success = false
        var online = true
        client.execute(bulkIndex).success { (result) in
            // `errors` can be either boolean (false) or number (eg. 3), so we need to parse that
            if let errors = result["errors"], NSString(string: "\(errors)").boolValue {
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
                NSLog("Non-success status code received from logsene receiver: \(response.statusCode), response:\n\(String(describing: maybeData))")
            }
        }.wait()

        if !success && online {
            return attemptExecute(bulkIndex, attempts: attempts - 1)
        }

        return success
    }
}

extension Worker: CLLocationManagerDelegate {
    #if os(macOS)
    #else
    func locationManager(_ manager: CLLocationManager, didVisit visit: CLVisit) {
        NSLog("Setting location to %d %d", Double(visit.coordinate.latitude),  Double(visit.coordinate.longitude))
        self.locationSet = true
        self.currentLatitude = Double(visit.coordinate.latitude)
        self.currentLongitude = Double(visit.coordinate.longitude)
    }
    #endif
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        #if os(macOS)
        #else
        if locations.first != nil {
            self.currentLatitude = locations.first?.coordinate.latitude
            self.currentLongitude = locations.first?.coordinate.longitude
            if (self.currentLongitude != 0.0 && self.currentLatitude != 0.0) {
                self.locationSet = true
            }
        }
        #endif
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        NSLog("Unable to get location data: \(error.localizedDescription)")
    }
    
    func readInitialLocation() {
        #if os(macOS)
        #else
        NSLog("Reading initial location")
        if #available(iOS 9.0, *) {
            self.locationManager?.requestLocation()
        }
        #endif
    }
}
