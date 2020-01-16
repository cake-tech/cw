import Foundation
import CakeWalletLib
import CWMonero

final class NodesList: Collection {
    static let shared: NodesList = NodesList()
    
    private static func load() -> [[String: Any]] {
        if !FileManager.default.fileExists(atPath: url.path) {
           
            try! copyOriginToDocuments()
            
        }
        
        if  let documentsPlistData = try? Data(contentsOf:url),
            let originalPlistData = try? Data(contentsOf:originalNodesListUrl),
            let originalSerialized = try! PropertyListSerialization.propertyList(from: originalPlistData, options:[], format:nil) as? [[String:Any]],
            var documentSerialized = try! PropertyListSerialization.propertyList(from: documentsPlistData, options:[], format:nil) as? [[String:Any]]
        {
            print("bundled node plist has \(originalSerialized.count) nodes")
            print("document plist data contains \(documentSerialized.count) nodes")
            
            //inject the "isUserDeleted" key for every node in the document plist that does not contain is key
            documentSerialized = documentSerialized.map({ someNode in
                if someNode["isUserDeleted"] as? Bool == nil {
                    var someNodeModify = someNode
                    someNodeModify["isUserDeleted"] = false
                    return someNodeModify
                } else {
                    return someNode
                }
            })
            
            //these are the nodes that the user will see
            var userNodes = documentSerialized.filter({ someNode in
                if let hasIsUserDeleted = someNode["isUserDeleted"] as? Bool {
                    return !hasIsUserDeleted
                } else {
                    return true
                }
            })

            let allDocumentNodeURIs = documentSerialized.compactMap({ $0["uri"] as? String })
            
            for (_, currentBundledNode) in originalSerialized.enumerated() {
                if let thisNodeURI = currentBundledNode["uri"] as? String {
                    if allDocumentNodeURIs.contains(thisNodeURI) == false {
                        userNodes.append(currentBundledNode)
                    }
                }
            }
            
            return userNodes
        }
        
        return []
    }
    
    private static func copyOriginToDocuments() throws {
        try FileManager.default.copyItem(at: originalNodesListUrl, to: url)
    }
    
    static let originalNodesListUrl = Bundle.main.url(forResource: "NodesList", withExtension: "plist")!
    static var url: URL {
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("NodesList.plist")
    }
    private var content: [[String: Any]] = []
    var values: [NodeDescription] {
        return content.map { node -> NodeDescription? in
            if let uri = node["uri"] as? String {
                //fixme
                return MoneroNodeDescription(
                    uri: uri,
                    login: node["login"] as? String ?? "",
                    password: node["password"] as? String ?? ""
                )
            } else {
                return nil
            }
            }.compactMap({ $0 })
    }
    
    var count: Int {
        return content.count
    }
    
    var startIndex: Int {
        return content.startIndex
    }
    
    var endIndex: Int {
        return content.endIndex
    }
    
    subscript(position: Int) -> NodeDescription {
        //fixme
        return MoneroNodeDescription(
            uri: content[position]["uri"] as? String ?? "",
            login: content[position]["login"] as? String ?? "",
            password: content[position]["password"] as? String ?? "")
    }
    
    private init() {
        content = NodesList.load()
    }
    
    func index(after i: Int) -> Int {
        return content.index(after: i)
    }
    
    func add(node: NodeDescription) throws {
        content.append(node.toDictionary())
        try save()
    }
    
    func remove(at index: Int) throws {
        var nodeToFlagAsRemoved = self.content[index]
        nodeToFlagAsRemoved["isUserDeleted"] = true
        self.content[index] = nodeToFlagAsRemoved
        let content = self.content as NSArray
        if #available(iOS 11.0, *) {
            try content.write(to: NodesList.url)
        } else {
            // Fallback on earlier versions
        }
        self.content = Self.load()
    }
    
    func reset() throws {
        if NodesList.originalNodesListUrl != NodesList.url {
            try FileManager.default.removeItem(at: NodesList.url)
            try FileManager.default.copyItem(at: NodesList.originalNodesListUrl, to: NodesList.url)
        }
        
        content = NodesList.load()
    }
    
    func save() throws {
        let content = self.content as NSArray
        if #available(iOS 11.0, *) {
            try content.write(to: NodesList.url)
        } else {
            // Fallback on earlier versions
        }
    }
}

extension NodeDescription {
    func toDictionary() -> [String: Any] {
        var dir = [String: Any]()
        
        if !login.isEmpty {
            dir["login"] = login
        }
        
        if !password.isEmpty {
            dir["password"] = password
        }
        
        dir["uri"] = uri
        return dir
    }
}
