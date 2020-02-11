import Foundation

public extension NSDate {

    /// Returns a string timestamp suitable for use in Logsene `@timestamp` field.
    func logseneTimestamp() -> String {
        let dateFormatter = NSDateFormatter()
        let enUSPosixLocale = NSLocale(localeIdentifier: "en_US_POSIX")
        dateFormatter.locale = enUSPosixLocale
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        return dateFormatter.stringFromDate(self)
    }
}
