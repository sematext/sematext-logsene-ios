/// Represents the bulk index request.
class BulkIndex {
    let documents: [(source: String, type: String)]

    init(documents: [(source: String, type: String)]) {
        self.documents = documents
    }

    func toBody(index: String) -> String {
        var body = ""
        for document in documents {
            body += "{ \"index\" : { \"_index\": \"\(index)\", \"_type\" : \"\(document.type)\" } }\n"
            body += document.source.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet()) + "\n"
        }
        return body
    }
}

/// Basic promise implementation.
class Promise<T> {
    private var successCb: ((T) -> ())?
    private var failureCb: ((NSError?, NSHTTPURLResponse?, NSData?) -> ())?
    private var alwaysCb: (() -> ())?
    private let semaphore = dispatch_semaphore_create(0)
    private let semaphoreTimeout: NSTimeInterval?

    init() {
        self.semaphoreTimeout = nil
    }

    init(semaphoreTimeout: NSTimeInterval) {
        self.semaphoreTimeout = semaphoreTimeout
    }

    func finish(obj: T) {
        successCb?(obj)
        alwaysCb?()
        dispatch_semaphore_signal(semaphore)
    }

    func raiseError(error: NSError?, response: NSHTTPURLResponse? = nil, data: NSData? = nil) {
        failureCb?(error, response, data)
        alwaysCb?()
        dispatch_semaphore_signal(semaphore)
    }

    func success(successCb: (T) -> ()) -> Promise<T> {
        self.successCb = successCb;
        return self
    }

    func failure(failureCb: (NSError?, NSHTTPURLResponse?, NSData?) -> ()) -> Promise<T> {
        self.failureCb = failureCb
        return self
    }

    func always(alwaysCb: () -> ()) -> Promise<T> {
        self.alwaysCb = alwaysCb
        return self
    }

    /// Waits until either the promise is finished, or an error is raised.
    func wait() {
        if let timeout = semaphoreTimeout {
            dispatch_semaphore_wait(semaphore, dispatch_time(DISPATCH_TIME_NOW, Int64(timeout * Double(NSEC_PER_SEC))))
        } else {
            dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER)
        }
    }
}


/// The base client for interacting with the Logsene api.
class LogseneClient {
    let receiverUrl: String
    let appToken: String
    let session: NSURLSession
    let configuration: NSURLSessionConfiguration

    /**
        Initializes the client.

        - Parameters:
            - receiverUrl: The url of the logsene receiver.
            - appToken: Your logsene app token.
    */
    init(receiverUrl: String, appToken: String, configuration: NSURLSessionConfiguration) {
        self.receiverUrl = LogseneClient.cleanReceiverUrl(receiverUrl)
        self.appToken = appToken
        self.configuration = configuration
        self.session = NSURLSession(configuration: configuration)
    }

    /**
        Executes a bulk index request.

        - Parameters:
            - bulkIndex: The bulk index request.
    */
    func execute(bulkIndex: BulkIndex) -> Promise<JsonObject> {
        let request = prepareRequest(NSURL(string: "\(receiverUrl)/_bulk")!, method: "POST")
        request.HTTPBody = bulkIndex.toBody(appToken).dataUsingEncoding(NSUTF8StringEncoding)
        return execute(request)
    }

    private func execute(request: NSURLRequest) -> Promise<JsonObject> {
        let promise = Promise<JsonObject>(semaphoreTimeout: self.configuration.timeoutIntervalForResource)
        let task = NSURLSession.sharedSession().dataTaskWithRequest(request) { (maybeData, maybeResponse, maybeError) in
            if let error = maybeError {
                promise.raiseError(error, response: maybeResponse as? NSHTTPURLResponse)
                return
            }

            if let response = maybeResponse as? NSHTTPURLResponse {
                // if status code not in success range (200-299), fail the promise
                if response.statusCode < 200 || response.statusCode > 299  {
                    promise.raiseError(maybeError, response: response, data: maybeData)
                    return
                }
            }

            if let data = maybeData {
                if let jsonObject = (try? NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions())) as? JsonObject {
                    promise.finish(jsonObject)
                } else {
                    NSLog("Couldn't deserialize json response, returning empty json object instead")
                    return promise.finish([:])
                }
            }
        }
        task.resume()
        return promise
    }

    private func prepareRequest(url: NSURL, method: String) -> NSMutableURLRequest {
        let request = NSMutableURLRequest(URL: NSURL(string: "\(receiverUrl)/_bulk")!)
        request.HTTPMethod = method
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        return request
    }

    private class func cleanReceiverUrl(url: String) -> String {
        let cleaned = url.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
        if cleaned.hasSuffix("/") {
            return cleaned.substringToIndex(cleaned.endIndex.advancedBy(-1))
        } else {
            return cleaned
        }
    }
}
