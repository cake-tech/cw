import UIKit
import CakeWalletLib
import CWMonero

extension TransactionDescription {
    func recipientAddress() -> String? {
        return nil
//        return RecipientAddresses.shared.getRecipientAddress(by: id)
    }
    
    func tradeId() -> String? {
        return ExchangeTransactions.shared.getTradeID(by: id)
    }
    
    func exchangeProvider() -> String? {
        return ExchangeTransactions.shared.getExchangeProvider(by: id)
    }
}
