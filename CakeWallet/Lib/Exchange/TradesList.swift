import CryptoSwift
import CakeWalletLib
import CakeWalletCore
import SwiftyJSON

class TradesList {
    static let shared = TradesList()
    
    private static let key = try! KeychainStorageImpl.standart.fetch(forKey: .masterPassword)
        .replacingOccurrences(of: "-", with: "")
        .data(using: .utf8)?.bytes ?? []
    private static let iv = AppSecrets.keychainSalt.data(using: .utf8)?.bytes ?? []
    
    private static var url: URL {
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("trades_list.json")
    }
    
    let file: File
    
    init(file: File = EncryptedFile(
        url: TradesList.url,
        cipherBuiler: {
            let key = try! PKCS5.PBKDF2(password: TradesList.key, salt:  TradesList.iv, iterations: 4096, variant: .sha256).calculate()
            return try! Blowfish(key: key, padding: .pkcs7)
    })) {
        self.file = file
    }
    
    func add(tradeID: String, date: Date, provider: ExchangeProvider, from: CryptoCurrency, to: CryptoCurrency) {
        do {
            let json = file.contentJSON() ?? JSON()
            let trade = JSON([
                "tradeID": tradeID,
                "date": date.timeIntervalSince1970,
                "provider": provider.rawValue,
                "from": from.formatted(),
                "to": to.formatted()])
            let res = json.arrayValue + [trade]
            try file.save(json: JSON(res))
        } catch {
            print(error)
        }
    }
    
    func list() -> [TradeInfo] {
        return file.contentJSON()?.arrayValue.map({ TradeInfo(json: $0) }) ?? []
    }
    
    func get(byID id: String) -> TradeInfo? {
        return file.contentJSON()?.arrayValue
            .filter({ $0.dictionaryValue["tradeID"]?.stringValue == id })
            .map({ TradeInfo(json: $0) })
            .first
    }
}
