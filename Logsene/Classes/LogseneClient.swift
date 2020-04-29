import Foundation

/// Represents the bulk index request.
class BulkIndex {
    let documents: [(source: String, type: String)]

    init(documents: [(source: String, type: String)]) {
        self.documents = documents
    }

    func toBody(_ index: String) -> String {
        var body = ""
        for document in documents {
            body += "{ \"index\" : { \"_index\": \"\(index)\", \"_type\" : \"\(document.type)\" } }\n"
            body += document.source.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines) + "\n"
        }
        return body
    }
}

/// Basic promise implementation.
class Promise<T> {
    fileprivate var successCb: ((T) -> ())?
    fileprivate var failureCb: ((NSError?, HTTPURLResponse?, Data?) -> ())?
    fileprivate var alwaysCb: (() -> ())?
    fileprivate let semaphore = DispatchSemaphore(value: 0)
    fileprivate let semaphoreTimeout: TimeInterval?

    init() {
        self.semaphoreTimeout = nil
    }

    init(semaphoreTimeout: TimeInterval) {
        self.semaphoreTimeout = semaphoreTimeout
    }

    func finish(_ obj: T) {
        successCb?(obj)
        alwaysCb?()
        semaphore.signal()
    }

    func raiseError(_ error: NSError?, response: HTTPURLResponse? = nil, data: Data? = nil) {
        failureCb?(error, response, data)
        alwaysCb?()
        semaphore.signal()
    }

    func success(_ successCb: @escaping (T) -> ()) -> Promise<T> {
        self.successCb = successCb;
        return self
    }

    func failure(_ failureCb: @escaping (NSError?, HTTPURLResponse?, Data?) -> ()) -> Promise<T> {
        self.failureCb = failureCb
        return self
    }

    func always(_ alwaysCb: @escaping () -> ()) -> Promise<T> {
        self.alwaysCb = alwaysCb
        return self
    }

    /// Waits until either the promise is finished, or an error is raised.
    func wait() {
        if let timeout = semaphoreTimeout {
           _ = semaphore.wait(timeout: DispatchTime.now() + Double(Int64(timeout * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC))
        } else {
           _ = semaphore.wait(timeout: DispatchTime.distantFuture)
        }
    }
}

/// The base client for interacting with the Logsene api.
class LogseneClient {
    let receiverUrl: String
    let appToken: String
    let session: URLSession
    let configuration: URLSessionConfiguration

    /**
        Initializes the client.

        - Parameters:
            - receiverUrl: The url of the logsene receiver.
            - appToken: Your logsene app token.
    */
    init(receiverUrl: String, appToken: String, configuration: URLSessionConfiguration) {
        self.receiverUrl = LogseneClient.cleanReceiverUrl(receiverUrl)
        self.appToken = appToken
        self.configuration = configuration
        self.session = URLSession(configuration: configuration)
    }

    /**
        Executes a bulk index request.

        - Parameters:
            - bulkIndex: The bulk index request.
    */
    func execute(_ bulkIndex: BulkIndex) -> Promise<JsonObject> {
        let request = prepareRequest(URL(string: "\(receiverUrl)/_bulk")!, method: "POST")
        request.httpBody = bulkIndex.toBody(appToken).data(using: String.Encoding.utf8)
        return execute(request as URLRequest)
    }

    fileprivate func execute(_ request: URLRequest) -> Promise<JsonObject> {
        let promise = Promise<JsonObject>(semaphoreTimeout: self.configuration.timeoutIntervalForResource)
        let task = URLSession.shared.dataTask(with: request, completionHandler: { (maybeData, maybeResponse, maybeError) in
            if let error = maybeError {
                promise.raiseError(error as NSError?, response: maybeResponse as? HTTPURLResponse)
                return
            }

            if let response = maybeResponse as? HTTPURLResponse {
                // if status code not in success range (200-299), fail the promise
                if response.statusCode < 200 || response.statusCode > 299  {
                    promise.raiseError(maybeError as NSError?, response: response, data: maybeData)
                    return
                }
            }

            if let data = maybeData {
                if let jsonObject = (try? JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions())) as? JsonObject {
                    promise.finish(jsonObject)
                } else {
                    NSLog("Couldn't deserialize json response, returning empty json object instead")
                    return promise.finish([:])
                }
            }
        })
        task.resume()
        return promise
    }

    fileprivate func prepareRequest(_ url: URL, method: String) -> NSMutableURLRequest {
        let request = NSMutableURLRequest(url: URL(string: "\(receiverUrl)/_bulk")!)
        request.httpMethod = method
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        return request
    }

    fileprivate class func cleanReceiverUrl(_ url: String) -> String {
        let cleaned = url.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        if cleaned.hasSuffix("/") {
            let endIndex = cleaned.index(cleaned.endIndex, offsetBy: -1)
            return String(cleaned[...endIndex])
        } else {
            return cleaned
        }
    }
}
