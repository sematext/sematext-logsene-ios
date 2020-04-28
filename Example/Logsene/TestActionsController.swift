import UIKit
import Foundation
import AudioToolbox
import Logsene

enum MyErrors: Error {
    case notImplementedError
}

extension MyErrors: CustomStringConvertible {
    var description: String {
        switch self {
        case .notImplementedError:
            return "This is not implemented yet"
        }
    }
}

class TestActionsController: UITableViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    @IBAction func logMessageTap(_ sender: AnyObject) {
        AudioServicesPlaySystemSound(1105)
        LLogInfo("Logging an info message")
    }

    @IBAction func logExceptionTap(_ sender: AnyObject) {
        AudioServicesPlaySystemSound(1105)
        do {
            // always fails
            try failWithError()
        } catch let err {
            LLogError(err)
        }
    }

    @IBAction func logWithNSLog(_ sender: AnyObject) {
        AudioServicesPlaySystemSound(1105)
        NSLog("Logging with NSLog")
    }


    func failWithError() throws {
        throw MyErrors.notImplementedError
    }
}
