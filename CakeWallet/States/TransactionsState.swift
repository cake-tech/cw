import CakeWalletLib
import CakeWalletCore

public struct TransactionsState: StateType {
    public static func == (lhs: TransactionsState, rhs: TransactionsState) -> Bool {
        return lhs.sendingStage == rhs.sendingStage
            && lhs.transactions == rhs.transactions
            && lhs.estimatedFee.compare(with: rhs.estimatedFee)
    }
    
    public enum Action: AnyAction {
        case newTransaction(TransactionDescription)
        case reset([TransactionDescription])
        case changedSendingStage(SendingStage)
        case changedEstimatedFee(Amount)
    }
    
    public let transactions: [TransactionDescription]
    public let sendingStage: SendingStage
    public let estimatedFee: Amount
    
    public init(transactions: [TransactionDescription], sendingStage: SendingStage, estimatedFee: Amount) {
        let groupedByID = Dictionary(grouping:transactions, by: { $0.id }).compactMapValues({ someTrans -> [TransactionDescription] in
            if someTrans.count > 1 {
                return someTrans.filter { $0.isPending == false }
            }
            return someTrans
        })
        self.transactions = groupedByID.values.flatMap({ $0 }).sorted(by: { $0.date > $1.date })
        self.sendingStage = sendingStage
        self.estimatedFee = estimatedFee
    }
    
    public func reduce(_ action: TransactionsState.Action) -> TransactionsState {
        switch action {
        case let .reset(transactions):
            return TransactionsState(transactions: transactions, sendingStage: sendingStage, estimatedFee: estimatedFee)
        case let .newTransaction(transaction):
            let transactions = self.transactions + [transaction]
            return TransactionsState(transactions: transactions, sendingStage: sendingStage, estimatedFee: estimatedFee)
        case let .changedSendingStage(sendingStage):
            return TransactionsState(transactions: transactions, sendingStage: sendingStage, estimatedFee: estimatedFee)
        case let .changedEstimatedFee(fee):
            return TransactionsState(transactions: transactions, sendingStage: sendingStage, estimatedFee: fee)
        }
    }
}
