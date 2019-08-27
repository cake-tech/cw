import Foundation
import CakeWalletLib
import CWMonero
import CryptoSwift
import SwiftyJSON

class RecipientAddresses {
    static let shared: RecipientAddresses = RecipientAddresses()
    
    static var url: URL {
        return MoneroWalletGateway().makeDirURL(for: store.state.walletState.name).appendingPathComponent("recipients.json")
    }
    
    private static let key = try! KeychainStorageImpl.standart.fetch(forKey: .masterPassword)
        .replacingOccurrences(of: "-", with: "")
        .data(using: .utf8)?.bytes ?? []
    private static let iv = store.state.walletState.name.data(using: .utf8)?.bytes ?? []
    
    let file: File
    
    init(file: File = EncryptedFile(
        url: RecipientAddresses.url,
        cipherBuiler: {
            let key = try! PKCS5.PBKDF2(password: RecipientAddresses.key, salt:  RecipientAddresses.iv, iterations: 4096, variant: .sha256).calculate()
            return try! Blowfish(key: key, padding: .pkcs7)
    })) {
        self.file = file
    }
    
    func save(forTransactionId transactionId: String, andRecipientAddress recipientAddress: String) {
        do {
            var json = file.contentJSON() ?? JSON()
            json.dictionaryObject?[transactionId] = recipientAddress
            try file.save(json: json)
        } catch {
            print(error)
        }
    }
    
    func getRecipientAddress(by id: String) -> String? {
        return file.contentJSON()?[id].string
    }
}
