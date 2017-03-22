import Foundation

extension String {
    init?(jsonObject: JsonObject, options: JSONSerialization.WritingOptions = JSONSerialization.WritingOptions()) {
        if let data = try? JSONSerialization.data(withJSONObject: jsonObject, options: options) {
            self.init(data: data, encoding: String.Encoding.utf8)
        } else {
            return nil
        }
    }
}
