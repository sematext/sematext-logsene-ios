import Foundation

extension String {
    init?(jsonObject: JsonObject, options: NSJSONWritingOptions = NSJSONWritingOptions()) {
        if let data = try? NSJSONSerialization.dataWithJSONObject(jsonObject, options: options) {
            self.init(data: data, encoding: NSUTF8StringEncoding)
        } else {
            return nil
        }
    }
}
