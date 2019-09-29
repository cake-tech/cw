import CakeWalletLib
import CakeWalletCore
import SwiftyJSON

protocol JSONExportable {
    var primaryKey: String { get }
    func toJSON() -> JSON
}

protocol JSONImportable {
    init?(from json: JSON)
}

protocol JSONConvertable: JSONExportable, JSONImportable {}

struct Contact {
    let uuid: String
    let type: CryptoCurrency
    let name: String
    let address: String
    
    init(uuid: String? = nil, type: CryptoCurrency, name: String, address: String) {
        if let uuid = uuid {
            self.uuid = uuid
        } else {
            self.uuid = UUID().uuidString
        }
        
        self.type = type
        self.name = name
        self.address = address
    }
}

extension Contact: JSONConvertable {
    init?(from json: JSON) {
        guard
            let typeRaw = json["type"].string,
            let type = CryptoCurrency(from: typeRaw) else {
                return nil
        }
        
        self.uuid = json["uuid"].stringValue
        self.type = type
        self.name = json["name"].stringValue
        self.address = json["address"].stringValue
    }
    
    var primaryKey: String {
        return "uuid"
    }
    
    func toJSON() -> JSON {
        return JSON(["uuid": uuid, "name": name, "type": type.formatted(), "address": address])
    }
}

extension Contact: CellItem {
    private func backgroundColor(for currency: CryptoCurrency) -> UIColor {
        switch currency {
        case .bitcoin:
            return UIColor(hex: 0xfe9a2b)
        case .bitcoinCash:
            return UIColor(hex: 0xec8c38)
        case .monero:
            return UserInterfaceTheme.current.blue.dim
        case .ethereum:
            return UIColor(hex: 0x303030)
        case .liteCoin:
            return UIColor(hex: 0x88caf2)
        case .dash:
            return UIColor(hex: 0x068de0)
        }
    }
    
    private func textColor(for currency: CryptoCurrency) -> UIColor {
        switch currency {
        case .bitcoin:
            return .white
        case .bitcoinCash:
            return .white
        case .monero:
            return UserInterfaceTheme.current.blue.highlight
        case .ethereum:
            return .white
        case .liteCoin:
            return .white
        case .dash:
            return .white
        }
    }
    
    func setup(cell: AddressTableCell) {
        cell.configure(
            name: name,
            type: type.formatted(),
            backgroundColor: backgroundColor(for: type),
            textColor: textColor(for: type)
        )
    }
}
