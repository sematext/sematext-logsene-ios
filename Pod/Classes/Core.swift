import Foundation

/// Alias for dictionary String:AnyObject, but must be a valid json object (enforced in LLogEvent()).
public typealias JsonObject = [String: Any]

/// Holds static information.
struct Logsene {
    static var worker: Worker?
    static var onceToken = NSUUID().uuidString
    static var defaultMeta: [String: Any]?
}

/**
    Initializes the Logsene framework.

    You will most likely want to call this from your application delegate in [application:didFinishLaunchingWithOptions:](https://developer.apple.com/library/ios/documentation/UIKit/Reference/UIApplicationDelegate_Protocol/index.html#//apple_ref/occ/intfm/UIApplicationDelegate/application:didFinishLaunchingWithOptions:)

    - Parameters:
        - appToken: Your Logsene application token.
        - type: The Elasticsearch type to use for all events.
        - receiverUrl: The receiver url (optional).
        - maxOfflineMessages: The maximum number of messages (5,000 by default) stored while device is offline (optional).
*/
public func LogseneInit(_ appToken: String, type: String, receiverUrl: String = "https://logsene-receiver.sematext.com", maxOfflineMessages: Int = 5000) throws {
    var maybeError: Error? = nil
    DispatchQueue.once(token: Logsene.onceToken) {
        let client = LogseneClient(receiverUrl: receiverUrl, appToken: appToken, configuration: URLSessionConfiguration.default)
        do {
            Logsene.worker = try Worker(client: client, type: type, maxOfflineMessages: maxOfflineMessages)
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
    Logs an event.

    The event can be any valid json document.

    - Precondition: `event` must be a valid json object.
*/
public func LLogEvent(_ event: JsonObject) {
    precondition(JSONSerialization.isValidJSONObject(event), "event must be a valid json object.")
    if let worker = Logsene.worker {
        var enrichedEvent = event
        enrichEvent(&enrichedEvent)
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

/// Logs a simple message with `level` set to `warn`.
public func LLogWarn(_ message: String) {
    LLogEvent(["level": "warn", "message": message])
}

/// Logs a simple message with `level` set to `error`.
public func LLogError(_ message: String) {
    LLogEvent(["level": "error", "message": message])
}

/// Logs an error.
public func LLogError(_ error: Error) {
    LLogEvent(["level": "error", "message": "\(error)"])
}

/// Logs an error.
public func LLogDebug(_ error: Error) {
    LLogEvent(["level": "debug", "message": "\(error)"])
}

/// Logs an error.
public func LLogError(_ error: NSError) {
    LLogEvent(["level": "error", "message": "\(error.localizedDescription)", "errorCode": error.code])
}

/// Logs an error.
public func LLogError(_ error: NSException) {
    LLogEvent(["level": "error", "message": error.description, "exceptionName": error.name, "exceptionReason": "\(error.reason)"])
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
        meta["uuid"] = UIDevice.current.identifierForVendor!.uuidString
        if let defaultMeta = Logsene.defaultMeta {
            for (key, value) in defaultMeta {
                meta[key] = value
            }
        }
        event["meta"] = meta
    }
}
