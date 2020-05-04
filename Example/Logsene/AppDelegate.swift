import UIKit
import Logsene
import CocoaLumberjack

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // NOTE: Set your token below
        try! LogseneInit("<your-token>", type: "example")
        LLogNSLogMessages()

        // Here we setup CocoaLumberjack to log to both XCode console and Logsene
        DDLog.add(DDTTYLogger.sharedInstance!)
        DDLog.add(LogseneLogger())
        DDLogInfo("hello world from CocoaLumberjack!")
        
        // Try sending log message with explicit location
        let location = LogsLocation(fromLatitude: 53.13, fromLongitude: 23.16)
        LLogInfo(withMessage: "This is a test message with location", withLocation: location)
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
    }

    func applicationWillTerminate(_ application: UIApplication) {
    }
}
