import CakeWalletLib
import CakeWalletCore

public struct BalanceState: StateType {
    public static func == (lhs: BalanceState, rhs: BalanceState) -> Bool {
        return lhs.balance.compare(with: rhs.balance)
            && lhs.unlockedBalance.compare(with: rhs.unlockedBalance)
            && lhs.unlockedFiatBalance.compare(with: rhs.unlockedFiatBalance)
            && lhs.price == rhs.price
            && lhs.rate == rhs.rate
    }
    
    public enum Action: AnyAction {
        case changedBalance(Amount)
        case changedUnlockedBalance(Amount)
        case changedPrice(Double)
        case changedUnlockedFiatBalance(Amount)
        case changedFullFiatBalance(Amount)
        case changedRate(Double)
        case changePendingFiatBalance(Amount)
        case changePendingBalance(Amount)
    }
    
    public let balance: Amount
    public let unlockedBalance: Amount
    public let price: Double
    public let unlockedFiatBalance: Amount
    public let fullFiatBalance: Amount
    public let rate: Double
    public let pendingFiatBalance: Amount
    public let pendingBalance: Amount
    
    public init(balance: Amount, unlockedBalance: Amount, price: Double, fiatBalance: Amount, fullFiatBalance: Amount, rate: Double, pendingFiatBalance: Amount, pendingBalance: Amount) {
        self.balance = balance
        self.unlockedBalance = unlockedBalance
        self.fullFiatBalance = fullFiatBalance
        self.price = price
        self.unlockedFiatBalance = fiatBalance
        self.rate = rate
        self.pendingFiatBalance = pendingFiatBalance
        self.pendingBalance = pendingBalance
    }
    
    public func reduce(_ action: BalanceState.Action) -> BalanceState {
        switch action {
        case let .changedBalance(balance):
            return BalanceState(balance: balance, unlockedBalance: unlockedBalance, price: price, fiatBalance: unlockedFiatBalance, fullFiatBalance: fullFiatBalance, rate: rate, pendingFiatBalance: pendingFiatBalance, pendingBalance: pendingBalance)
        case let .changedUnlockedFiatBalance(fiatBalance):
            return BalanceState(balance: balance, unlockedBalance: unlockedBalance, price: price, fiatBalance: fiatBalance, fullFiatBalance: fullFiatBalance, rate: rate, pendingFiatBalance: pendingFiatBalance, pendingBalance: pendingBalance)
        case let .changedFullFiatBalance(fullFiatBalance):
            return BalanceState(balance: balance, unlockedBalance: unlockedBalance, price: price, fiatBalance: unlockedFiatBalance, fullFiatBalance: fullFiatBalance, rate: rate, pendingFiatBalance: pendingFiatBalance, pendingBalance: pendingBalance)
        case let .changedPrice(price):
            return BalanceState(balance: balance, unlockedBalance: unlockedBalance, price: price, fiatBalance: unlockedFiatBalance, fullFiatBalance: fullFiatBalance, rate: rate, pendingFiatBalance: pendingFiatBalance, pendingBalance: pendingBalance)
        case let .changedUnlockedBalance(unlockedBalance):
            return BalanceState(balance: balance, unlockedBalance: unlockedBalance, price: price, fiatBalance: unlockedFiatBalance, fullFiatBalance: fullFiatBalance, rate: rate, pendingFiatBalance: pendingFiatBalance, pendingBalance: pendingBalance)
        case let .changedRate(rate):
            return BalanceState(balance: balance, unlockedBalance: unlockedBalance, price: price, fiatBalance: unlockedFiatBalance, fullFiatBalance: fullFiatBalance, rate: rate, pendingFiatBalance: pendingFiatBalance, pendingBalance: pendingBalance)
        case let .changePendingBalance(newValue):
            return BalanceState(balance:balance, unlockedBalance: unlockedBalance, price:price, fiatBalance: unlockedFiatBalance, fullFiatBalance: fullFiatBalance, rate: rate, pendingFiatBalance: pendingFiatBalance, pendingBalance: newValue)
        case let.changePendingFiatBalance(newValue):
            return BalanceState(balance:balance, unlockedBalance: unlockedBalance, price:price, fiatBalance: unlockedFiatBalance, fullFiatBalance: fullFiatBalance, rate: rate, pendingFiatBalance: newValue, pendingBalance: pendingBalance)
        }
    }
}
