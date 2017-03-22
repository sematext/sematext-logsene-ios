import Foundation

/// Represents the C function signature used under-the-hood by NSLog
typealias NSLogCStringFunc = (UnsafePointer<CChar>, UInt32, Bool) -> Void

/// Sets the C function used by NSLog
@_silgen_name("_NSSetLogCStringFunction")
func _NSSetLogCStringFunction(_: NSLogCStringFunc) -> Void

/// Retrieves the current C function used by NSLog
@_silgen_name("_NSLogCStringFunction")
func _NSLogCStringFunction() -> NSLogCStringFunc?

/**
    Intercepts all NSLog messages and sends them to Logsene.

    - Parameters:
        - logToConsole: If set to true, messages will be logged with print() as well.
*/
public func LLogNSLogMessages(_ logToConsole: Bool = true) {
    _NSSetLogCStringFunction() { (cstr, length, syslogBanner) in
        if let message = String(validatingUTF8: cstr) {
            print("nslog: \(message)")
            LLogInfo(message)
        }
    }
}
