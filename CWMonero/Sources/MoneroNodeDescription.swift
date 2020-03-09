import Foundation
import Alamofire
import CakeWalletLib
import SwiftyJSON
import UIKit

public class MoneroNodeDescription: NSObject, NodeDescription {
    public let uri: String
    public let login: String
    public let password: String
    
    public init(uri: String, login: String = "", password: String = "") {
        self.uri = uri
        self.login = login
        self.password = password
    }
    
    public func isAble(_ handler: @escaping (Bool) -> Void) {
        let urlString = String(format: "http://%@/json_rpc", uri).addingPercentEncoding(withAllowedCharacters: .urlFragmentAllowed)!
        let requestBody: [String: Any] = [
            "jsonrpc": "2.0",
            "id": "0",
            "method": "get_info"
        ]
        var request = try! URLRequest(url: URL(string: urlString)!, method: .post)
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json;charset=UTF-8", forHTTPHeaderField: "Content-Type")
        request.httpBody = try! JSON(requestBody).rawData()
        var canConnect = false

        Alamofire.request(request)
            .response(completionHandler: { response in
                if let response = response.response {
                    canConnect = (response.statusCode >= 200 && response.statusCode < 300)
                        || response.statusCode == 401
                }
                
                handler(canConnect)
            })
    }
}
