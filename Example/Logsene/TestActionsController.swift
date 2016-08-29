import UIKit
import AudioToolbox
import Logsene

enum MyErrors: ErrorType {
    case NotImplementedError
}

extension MyErrors: CustomStringConvertible {
    var description: String {
        switch self {
        case .NotImplementedError:
            return "This is not implemented yet"
        }
    }
}

class TestActionsController: UITableViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    @IBAction func logMessageTap(sender: AnyObject) {
        AudioServicesPlaySystemSound(1105)
        LLogInfo("Logging an info message")
    }

    @IBAction func logExceptionTap(sender: AnyObject) {
        AudioServicesPlaySystemSound(1105)
        do {
            // always fails
            try failWithError()
        } catch let err {
            LLogError(err)
        }
    }

    @IBAction func logWithNSLog(sender: AnyObject) {
        AudioServicesPlaySystemSound(1105)
        NSLog("Logging with NSLog")
    }


    func failWithError() throws {
        throw MyErrors.NotImplementedError
    }
}
