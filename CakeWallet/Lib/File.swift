import SwiftyJSON
import CryptoSwift

class File {
    private static var lastUpdateTime: [URL: TimeInterval] = [:]
    private static var lastUpdateInstanceCounter: [URL: UInt32] = [:]
    
    private static func inc(for url: URL) {
        var c = lastUpdateInstanceCounter[url] ?? 0
        c += 1
        lastUpdateInstanceCounter[url] = c
    }
    
    private static func dec(for url: URL) {
        let c = lastUpdateInstanceCounter[url] ?? 0
        
        // is last element
        if c <= 1 {
            lastUpdateTime[url] = nil
            lastUpdateInstanceCounter[url] = nil
        }
    }
    
    private(set) var fileName: String
    private(set) var url: URL
    
    fileprivate var needUpdateContent: Bool {
        return lastUpdateTime > lastReadTime
    }
    
    fileprivate var lastUpdateTime: TimeInterval {
        return File.lastUpdateTime[url] ?? 0
    }
    
    fileprivate var lastReadTime: TimeInterval
    
    private var cachedJSONContent: JSON?
    private var cachedContent: Data?
    
    init(url: URL) {
        self.url = url
        self.fileName = url.lastPathComponent
        self.lastReadTime = 0
        File.inc(for: url)
    }
    
    deinit {
        File.dec(for: url)
    }
    
    func content() -> Data? {
        if
            let cachedContent = self.cachedContent,
            !needUpdateContent {
            return cachedContent
        }
        
        guard let content = try? Data(contentsOf: url) else {
            return nil
        }
        
        cachedContent = content
        updateLastReadTime()
        return content
    }
    
    func contentJSON() -> JSON? {
        if
            let cachedContent = self.cachedJSONContent,
            !needUpdateContent {
            return cachedContent
        }
        
        guard
            let data = content(),
            let json = try? JSON(data: data) else {
                return nil
        }
        
        cachedJSONContent = json
        return json
    }
    
    func save(json: JSON) throws {
        try save(data: json.rawData())
    }
    
    func save(data: Data) throws {
        try data.write(to: url)
        updateLastWriteTime()
    }
    
    fileprivate func updateLastWriteTime() {
        File.lastUpdateTime[url] = Date().timeIntervalSince1970
    }
    
    fileprivate func updateLastReadTime() {
        lastReadTime = Date().timeIntervalSince1970
    }
}

class EncryptedFile: File {
    let cipherBuiler: () -> Cipher
    
    private var decryptedContentJSON: JSON?
    private var decryptedData: Data?
    
    init(url: URL, cipherBuiler: @escaping () -> Cipher) {
        self.cipherBuiler = cipherBuiler
        super.init(url: url)
    }
    
    override func content() -> Data? {
        if
            let decryptedData = self.decryptedData,
            !needUpdateContent {
            return decryptedData
        }

        guard
            let data = super.content(),
            let decryptedBytes = try? cipherBuiler().decrypt(data.bytes) else {
            return nil
        }
        
        let decryptedData = Data(bytes: decryptedBytes)
        self.decryptedData = decryptedData
        updateLastReadTime()
        return decryptedData
    }
    
    override func contentJSON() -> JSON? {
        if
            let decryptedContentJSON = self.decryptedContentJSON,
            !needUpdateContent {
            return decryptedContentJSON
        }
        
        guard let data = content() else {
            return nil
        }
        
        let json = try? JSON(data: data)
        decryptedContentJSON = json
        return json
    }
    
    override func save(data: Data) throws {
        let encryptedBytes = try cipherBuiler().encrypt(data.bytes)
        let encryptedData = Data(bytes: encryptedBytes)
        try super.save(data: encryptedData)
    }
}
