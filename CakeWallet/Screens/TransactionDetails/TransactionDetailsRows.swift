import Foundation
import CakeWalletLib

enum TransactionDetailsRows: Stringify {
    case id, paymentId, recipientAddress, date, amount, height, fee, exchangeID, transactionKey, subaddresses, exchange
    
    func string() -> String {
        switch self {
        case .id:
            return NSLocalizedString("transaction_id", comment: "")
        case .paymentId:
            return NSLocalizedString("Payment ID", comment: "")
        case .recipientAddress:
            return NSLocalizedString("recipient_address", comment: "")
        case .date:
            return NSLocalizedString("date", comment: "")
        case .amount:
            return NSLocalizedString("amount", comment: "")
        case .height:
            return NSLocalizedString("height", comment: "")
        case .fee:
            return NSLocalizedString("fee", comment: "")
        case .exchange:
            return  NSLocalizedString("exchange_provider", comment: "")
        case .exchangeID:
            return NSLocalizedString("exchange_id", comment: "")
        case .transactionKey:
            return NSLocalizedString("transaction_key", comment: "")
        case .subaddresses:
            return NSLocalizedString("subaddresses", comment: "")
        }
    }
}
