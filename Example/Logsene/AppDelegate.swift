import UIKit
import Logsene
import CocoaLumberjack

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // NOTE: Set your token below
        try! LogseneInit("<yourtoken>", type: "example")
        LLogNSLogMessages()

        // Here we setup CocoaLumberjack to log to both XCode console and Logsene
        DDLog.add(DDTTYLogger.sharedInstance!)
        DDLog.add(LogseneLogger())
        DDLogInfo("hello world from CocoaLumberjack!")
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
