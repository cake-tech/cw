import Foundation
import CakeWalletLib

enum TradeDetailsRows: Stringify, CaseIterable {
    case tradeID, exchangeProvider, date, state, pair
    
    func string() -> String {
        switch self {
        case .tradeID:
            return  NSLocalizedString("trade_id", comment: "")
        case .date:
            return NSLocalizedString("date", comment: "")
        case .exchangeProvider:
            return  NSLocalizedString("exchange_provider", comment: "")
        case .state:
            return NSLocalizedString("state", comment: "")
        case .pair:
            return NSLocalizedString("pair", comment: "")
        }
    }
}

struct TradeDetailsCellItem: CellItem {
    let row: TradeDetailsRows
    let value: String
    
    func setup(cell: TransactionDetailsCell) {
        cell.configure(title: row.string() + ":", value: value)
    }
}
