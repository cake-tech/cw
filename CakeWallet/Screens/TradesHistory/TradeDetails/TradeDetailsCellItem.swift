import Foundation
import CakeWalletLib

enum TradeDetailsRows: Stringify, CaseIterable {
    case tradeID, exchangeProvider, date
    
    func string() -> String {
        switch self {
        case .tradeID:
            return "Trade ID"
        case .date:
            return "Date"
        case .exchangeProvider:
            return "Exchange provider"
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
