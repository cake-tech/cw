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
            return UserInterfaceTheme.current.gray.dim
        case .bitcoinCash:
            return UserInterfaceTheme.current.gray.dim
        case .monero:
            return UserInterfaceTheme.current.purple.dim
        case .ethereum:
            return UserInterfaceTheme.current.gray.dim
        case .liteCoin:
            return UserInterfaceTheme.current.gray.dim
        case .dash:
            return UserInterfaceTheme.current.gray.dim
        }
    }
    
    private func textColor(for currency: CryptoCurrency) -> UIColor {
        switch currency {
        case .bitcoin:
            return UserInterfaceTheme.current.gray.highlight
        case .bitcoinCash:
            return UserInterfaceTheme.current.gray.highlight
        case .monero:
            return UserInterfaceTheme.current.purple.highlight
        case .ethereum:
            return UserInterfaceTheme.current.gray.highlight
        case .liteCoin:
            return UserInterfaceTheme.current.gray.highlight
        case .dash:
            return UserInterfaceTheme.current.gray.highlight
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
