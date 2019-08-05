import Foundation
import CakeWalletLib

enum TradeDetailsRows: Stringify, CaseIterable {
    case tradeID, exchangeProvider, date, state
    
    func string() -> String {
        switch self {
        case .tradeID:
            return "Trade ID"
        case .date:
            return "Date"
        case .exchangeProvider:
            return "Exchange provider"
        case .state:
            return "State"
        }
    }
}

struct TradeDetailsCellItem: CellItem {
    var row: TradeDetailsRows
    var value: String
    
    func setup(cell: TransactionDetailsCell) {
        cell.configure(title: row.string() + ":", value: value)
    }
}
