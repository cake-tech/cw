import SwiftyJSON
import CryptoSwift

class File {
    private static var needUpdatesForFiles: [URL: Bool] = [:]
    private(set) var fileName: String
    private(set) var url: URL
    
    private var needUpdateContent: Bool {
        get { return File.needUpdatesForFiles[url] ?? false }
        set { File.needUpdatesForFiles[url] = true }
    }
    private var cachedContent: JSON?
    
    init(url: URL) {
        self.url = url
        self.fileName = url.lastPathComponent
    }
    
    deinit {
        File.needUpdatesForFiles[url] = nil
    }
    
    func content() -> Data? {
        return try? Data(contentsOf: url)
    }
    
    func contentJSON() -> JSON? {
        if let cachedContent = self.cachedContent, !needUpdateContent {
            return cachedContent
        }
        
        guard
            let data = try? Data(contentsOf: url),
            let json = try? JSON(data: data) else {
                return nil
        }
        
        cachedContent = json
        needUpdateContent = false
        return json
    }
    
    func save(json: JSON) throws {
        try save(data: json.rawData())
    }
    
    func save(data: Data) throws {
        try data.write(to: url)
        needUpdateContent = true
    }
    
}

class EncryptedFile: File {
    let cipher: Cipher
    
    private var decryptedContentJSON: JSON?
    
    init(url: URL, cipher: Cipher) {
        self.cipher = cipher
        super.init(url: url)
    }
    
    override func contentJSON() -> JSON? {
        if let decryptedContentJSON = self.decryptedContentJSON {
            return decryptedContentJSON
        }
        
        guard
            let raw = super.content(),
            let decryptedBytes = try? cipher.decrypt(raw.bytes) else {
            return nil
        }
        
        let decryptedData = Data(bytes: decryptedBytes)
        
        let json = try? JSON(data: decryptedData)
        
        decryptedContentJSON = json
        return json
    }
    
    override func save(data: Data) throws {
        let encryptedBytes = try cipher.encrypt(data.bytes)
        let encryptedData = Data(bytes: encryptedBytes)
        try super.save(data: encryptedData)
    }
}
