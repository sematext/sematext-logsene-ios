[logsene]: https://sematext.com/logsene/
[register]: https://apps.sematext.com/users-web/register.do
[hosted-kibana]: https://sematext.com/blog/2015/06/11/1-click-elk-stack-hosted-kibana-4/
[video-tutorials]: https://www.elastic.co/blog/kibana-4-video-tutorials-part-1

Logsene for iOS Applications
=============================

[![CI Status](http://img.shields.io/travis/Amir Hadzic/Logsene.svg?style=flat)](https://travis-ci.org/Amir Hadzic/Logsene)
[![Version](https://img.shields.io/cocoapods/v/Logsene.svg?style=flat)](http://cocoapods.org/pods/Logsene)
[![License](https://img.shields.io/cocoapods/l/Logsene.svg?style=flat)](http://cocoapods.org/pods/Logsene)
[![Platform](https://img.shields.io/cocoapods/p/Logsene.svg?style=flat)](http://cocoapods.org/pods/Logsene)

[Logsene is ELK as a Service][logsene]. This library lets you collect **mobile analytics** and **log data** from your iOS applications using Logsene. If you don't have a Logsene account, you can [register for free][register] to get your app token.

Getting Started
---------------

1. Logsene is available through [CocoaPods](http://cocoapods.org). To install it, simply add the following line to your Podfile:

```ruby
pod "Logsene"
```

2. Run `pod install`
3. Call `LogseneInit()` from your application delegate in `didFinishLaunchingWithOptions:`. For example:

```swift
@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        try! LogseneInit("<yourtoken>", type: "example")
    }
}
```

You can optionaly provide the `receiverUrl` parameter if you are using Logsene On Premises, and `maxOfflineMessages` to configure how many messages are stored while device is offline (5,000 by default).

**Note**: We highly recommend creating a write-only token in your application settings for use in your mobile apps.

Example Application
-------------------

You can try out the example application with Cocoapods:

```bash
cd ~/Desktop
pod try Logsene
```

Make sure to set your own application token in `AppDelegate.swift`.

Mobile Application Analytics
----------------------------

You can collect application analytics using Logsene. To do that, use the `LLogEvent()` function to send custom events. For example, you might want to send an event each time the user completes a game level:

```swift
LLogEvent(["event": "level_completed", "message": "Level 3 completed", "value": "3"])
```

To visualize the collected data, you would use the [integrated Kibana dashboard][hosted-kibana]. If you're new to Kibana, you can checkout [this video tutorials series][video-tutorials].

If you don't see the events in the dashboard immediately, note that we send the data in batches to preserve the battery (every 60s), or if we have more than 10 messages queued up. We also save the messages while the device is offline, so you don't have to worry about losing any data.

When it comes to the structure of your events, you are free to choose your own, the above is just an example. You can use any number of fields, and you can use nested fields. Basically, any valid JSON object will work fine. Note that we reserve the `meta` field for meta information (see below). If you set a value for this field when sending an event, we will not include any meta information for that event.

Meta Fields
-----------

We add some predefined meta fields to each event sent to Logsene. The fields are stored inside the "meta" field.

- versionName (app version string, eg. 1.0)
- versionCode (app build number, eg. 92)
- osRelease (iOS version, eg. 9.3.0)
- uuid (device identifier)

You can set your own meta fields with `LogseneSetDefaultMeta`. For example:

```swift
LogseneSetDefaultMeta(["user": "user@example.com", "plan": "free"])
```

Note that these meta fields are global, and will be attached to every event sent to Logsene.

Centralized Logging
-------------------

The library offers some basic functions for centralized logging:

- LLogDebug
- LLogInfo
- LLogWarn
- LLogError

For integrating with existing logging frameworks, see below.

### CocoaLumberjack

If you're using CocoaLumberjack for logging, you can use the custom Logsene logger to send log messages to Logsene automatically. You should configure CocoaLumberjack to use the Logsene logger:

```swift
@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // NOTE: Set your token below
        try! LogseneInit("<yourtoken>", type: "example")

        // Here we setup CocoaLumberjack to log to both XCode console and Logsene
        DDLog.addLogger(DDTTYLogger.sharedInstance())
        DDLog.addLogger(LogseneLogger())
        DDLogInfo("hello world from CocoaLumberjack!")
        return true
    }
}
```

We don't include the LogseneLogger in the pod, but you can find the [implementation here](Example/Logsene/Logger.swift). Feel free to use it in your own project.

### NSLog

We provide a mechanism for intercepting NSLog messages and sending them to Logsene. We use undocumented apis to accomplish this, so you should probably use CocaLumberjack instead. To send all NSLog messages to Logsene, call `LLogNSLogMessages()` just after `LogseneInit()`.


### How to log unhandled exceptions

You can log any unhandled Foundation exceptions by defining your own uncaught exception handler. For example:

```swift
@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // NOTE: Set your token below
        try! LogseneInit("<yourtoken>", type: "example")

        NSSetUncaughtExceptionHandler { exception in
            // log unhandled exception message
            LLogError(exception)
        }
        return true
    }
}
```
