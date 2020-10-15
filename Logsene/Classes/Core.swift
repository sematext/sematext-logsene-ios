import Foundation
#if os(macOS)
#else
import UIKit
#endif


/// Alias for dictionary String:AnyObject, but must be a valid json object (enforced in LLogEvent()).
public typealias JsonObject = [String: Any]

/// Holds static information.
struct Logsene {
    static var worker: Worker?
    static var onceToken = NSUUID().uuidString
    static var defaultMeta: [String: Any]?
}

/// Holds information about latitude and longitude
public class LogsLocation {
    var latitude: Double = 0.0
    var longitude: Double = 0.0
    
    public init(fromLatitude latitude: Double, fromLongitude longitude: Double) {
        self.latitude = latitude
        self.longitude = longitude
    }
}

/**
    Initializes the Logsene framework.

    You will most likely want to call this from your application delegate in [application:didFinishLaunchingWithOptions:]

    - Parameters:
        - appToken: Your Logsene application token.
        - type: The Elasticsearch type to use for all events.
        - receiverUrl: The receiver url (optional).
        - maxOfflineMessages: The maximum number of messages (5,000 by default) stored while device is offline (optional).
        - automaticLocationEnriching: When set to true the library will automatically enrich log events with location of the user (optional, false by default).
        - useLocationOnlyInForeground: When set to true the location data will only be used when the application is in foreground (optional, true by default).
*/
public func LogseneInit(_ appToken: String, type: String, receiverUrl: String = "https://logsene-receiver.sematext.com", maxOfflineMessages: Int = 5000, automaticLocationEnriching: Bool = false, useLocationOnlyInForeground: Bool = true) throws {
    var maybeError: Error? = nil
    DispatchQueue.once(token: Logsene.onceToken) {
        let client = LogseneClient(receiverUrl: receiverUrl, appToken: appToken, configuration: URLSessionConfiguration.default)
        do {
            Logsene.worker = try Worker(client: client, type: type, maxOfflineMessages: maxOfflineMessages, automaticLocationEnriching: automaticLocationEnriching, useLocationOnlyInForeground: useLocationOnlyInForeground)
        } catch (let err) {
            NSLog("Unable to initialize Logsene worker: \(err)")
            maybeError = err
        }
    }
    
    if let error = maybeError {
        throw error
    }
}

/**
    Sets the default meta fields.

    Meta fields are included with each event. We include version name, build, OS release, and UUID by default. Call this function to set your own, additional meta fields. For example:

    ```
    LogseneSetDefaultMeta(["user": "user@example.com"])
    ```

    Now each event will have a `user` field within the `meta` field.

    Call this function with `nil` to remove all custom meta fields.

    - Precondition: If not `nil`, `event` must be a valid json object.
*/
public func LogseneSetDefaultMeta(_ meta: JsonObject?) {
    if meta != nil {
        precondition(JSONSerialization.isValidJSONObject(meta!))
    }
    Logsene.defaultMeta = meta
}

/**
    Pauses sending logs until ```LogseneResumeSendingLogs()``` is called.
*/
public func LogsenePauseSendingLogs() {
    NSLog("Pausing the logs sending process")
    Logsene.worker?.pause()
}

/**
    Resumes paused logs sending.
*/
public func LogseneResumeSendingLogs() {
    NSLog("Resuming the logs sending process")
    Logsene.worker?.resume();
}

/**
    Logs an event.

    The event can be any valid json document.

    - Precondition: `event` must be a valid json object.
*/
public func LLogEvent(_ event: JsonObject) {
    precondition(JSONSerialization.isValidJSONObject(event), "event must be a valid json object.")
    if let worker = Logsene.worker {
        var enrichedEvent = event
        if worker.locationEnabled {
            enrichEvent(withEvent: &enrichedEvent, withLocationSet: worker.locationSet, withLatitude: worker.currentLatitude ?? 0.0, withLongitude: worker.currentLongitude ?? 0.0)
        } else {
            enrichEvent(&enrichedEvent)
        }
        // check if the log level is set and if it is not set it to INFO
        if enrichedEvent["level"] == nil {
            enrichedEvent["level"] = "info"
        }
        worker.addToQueue(enrichedEvent)
    } else {
        // TODO: do we make this a precondition?
        NSLog("Not logging the event, LogseneInit() needs to be called first!")
    }
}

/// Logs a simple message with `level` set to `info`.
public func LLogInfo(_ message: String) {
    LLogEvent(["level": "info", "message": message])
}

/// Logs a simple message with `level` set to `info` and including location.
public func LLogInfo(withMessage message: String, withLocation location: LogsLocation) {
    LLogEvent(["level": "info", "message": message, "lat": location.latitude, "lon": location.longitude])
}

/// Logs a simple message with `level` set to `warn`.
public func LLogWarn(_ message: String) {
    LLogEvent(["level": "warn", "message": message])
}

/// Logs a simple message with `level` set to `warn` and including location.
public func LLogWarn(withMessage message: String, withLocation location: LogsLocation) {
    LLogEvent(["level": "warn", "message": message, "lat": location.latitude, "lon": location.longitude])
}

/// Logs a simple message with `level` set to `error`.
public func LLogError(_ message: String) {
    LLogEvent(["level": "error", "message": message])
}

/// Logs a simple message with `level` set to `error` and including location.
public func LLogError(withMessage message: String, withLocation location: LogsLocation) {
    LLogEvent(["level": "error", "message": message, "lat": location.latitude, "lon": location.longitude])
}

/// Logs an error.
public func LLogError(_ error: Error) {
    LLogEvent(["level": "error", "message": "\(error)"])
}

/// Logs an error with location.
public func LLogError(withError error: Error, withLocation location: LogsLocation) {
    LLogEvent(["level": "error", "message": "\(error)", "lat": location.latitude, "lon": location.longitude])
}

/// Logs an error.
public func LLogDebug(_ error: Error) {
    LLogEvent(["level": "debug", "message": "\(error)"])
}

/// Logs an error with debug level with location.
public func LLogDebug(withError error: Error, withLocation location: LogsLocation) {
    LLogEvent(["level": "debug", "message": "\(error)", "lat": location.latitude, "lon": location.longitude])
}

/// Logs an error.
public func LLogError(_ error: NSError) {
    LLogEvent(["level": "error", "message": "\(error.localizedDescription)", "errorCode": error.code])
}

/// Logs an error with location.
public func LLogError(withError error: NSError, withLocation location: LogsLocation) {
    LLogEvent(["level": "error", "message": "\(error.localizedDescription)", "errorCode": error.code, "lat": location.latitude, "lon": location.longitude])
}

/// Logs an error.
public func LLogError(_ error: NSException) {
    LLogEvent(["level": "error", "message": error.description, "exceptionName": error.name, "exceptionReason": "\(String(describing: error.reason))"])
}

/// Logs an error with location.
public func LLogError(withError error: NSException, withLocation location: LogsLocation) {
    LLogEvent(["level": "error", "message": error.description, "exceptionName": error.name, "exceptionReason": "\(String(describing: error.reason))", "lat": location.latitude, "lon": location.longitude])
}

/// Enriches the event with meta information.
private func enrichEvent(_ event: inout JsonObject) {
    if event["@timestamp"] == nil {
        event["@timestamp"] = Date().logseneTimestamp()
    }

    if event["meta"] == nil {
        var meta: JsonObject = [:]
        if let infoDictionary = Bundle.main.infoDictionary {
            meta["versionName"] = infoDictionary["CFBundleShortVersionString"]!
            meta["versionCode"] = infoDictionary["CFBundleVersion"]!
        }
        let os = ProcessInfo.processInfo.operatingSystemVersion
        meta["osRelease"] = "\(os.majorVersion).\(os.minorVersion).\(os.patchVersion)"
        #if os(macOS)
        meta["osType"] = "MacOS"
        #else
        meta["osType"] = "iOS"
        meta["uuid"] = UIDevice.current.identifierForVendor!.uuidString
        #endif
        if let defaultMeta = Logsene.defaultMeta {
            for (key, value) in defaultMeta {
                meta[key] = value
            }
        }
        event["meta"] = meta
    }
    
    // if location is defined read it and create a new location entry in the event
    if event["lat"] != nil && event["lon"] != nil {
        let lat: Double = event["lat"] as! Double
        let lon: Double = event["lon"] as! Double
        event.removeValue(forKey: "lat")
        event.removeValue(forKey: "lon")
        var geo: JsonObject = [:]
        geo["location"] = "\(lat),\(lon)"
        event["geo"] = geo
    }
}

private func enrichEvent(withEvent event: inout JsonObject, withLocationSet locationSet: Bool, withLatitude latitude: Double, withLongitude longitude: Double) {
    enrichEvent(&event)
    if locationSet {
        event["location"] = "\(latitude),\(longitude)"
    }
}
