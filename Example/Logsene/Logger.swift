import Foundation
import Logsene
import CocoaLumberjack

/**
    Logsene logger for CocoaLumberjack.
*/
class LogseneLogger: DDAbstractLogger {
    override func log(message logMessage: DDLogMessage) {
        var message = logMessage.message

        // See https://github.com/CocoaLumberjack/CocoaLumberjack/issues/643
        let ivar = class_getInstanceVariable(object_getClass(self), "_logFormatter")
        if let formatter = object_getIvar(self, ivar) as? DDLogFormatter {
            message = formatter.format(message: logMessage)!
        }

        LLogEvent([
            "@timestamp": logMessage.timestamp.logseneTimestamp(),
            "level": LogseneLogger.formatLogLevel(logMessage.flag),
            "fileName": logMessage.fileName,
            "line": logMessage.line,
            "message": message,
            "threadID": logMessage.threadID,
            "threadName": logMessage.threadName
        ])
    }

    fileprivate class func formatLogLevel(_ level: DDLogFlag) -> String {
        switch level {
        case DDLogFlag.debug:
            return "debug"
        case DDLogFlag.error:
            return "error"
        case DDLogFlag.info:
            return "info"
        case DDLogFlag.verbose:
            return "verbose"
        case DDLogFlag.warning:
            return "warn"
        default:
            return "other"
        }
    }
}
