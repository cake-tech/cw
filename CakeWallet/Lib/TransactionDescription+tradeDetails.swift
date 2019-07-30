import UIKit
import CakeWalletLib
import CWMonero

extension TransactionDescription {
    func tradeId() -> String? {
        return ExchangeTransactions.shared.getTradeID(by: id)
    }
    
    func exchangeProvider() -> String? {
        return ExchangeTransactions.shared.getExchangeProvider(by: id)
    }
}
