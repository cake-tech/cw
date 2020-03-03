import CakeWalletLib

private let deep = 1000000000000 as Double
private var moneroAmountFormatter = { () -> NumberFormatter in
    let formatter = NumberFormatter()
    formatter.isLenient = false
    formatter.alwaysShowsDecimalSeparator = true
    formatter.locale = Locale(identifier: "en_US")
    formatter.numberStyle = .decimal
    formatter.maximumFractionDigits = 12
    formatter.minimumFractionDigits = 1
    
    return formatter
}()

func moneroAmountToString(amount: UInt64) -> String {
    let damount = Double(amount) / deep
    return moneroAmountFormatter.string(from: NSNumber(value: damount)) ?? "0.0"
}

func stringToMoneroAmount(string: String) -> UInt64 {
    let damount = (Double(string) ?? 0.0) * deep
    return UInt64(damount)
}

extension String {
    subscript(_ range: CountableRange<Int>) -> String {
        let idx1 = index(startIndex, offsetBy: max(0, range.lowerBound))
        let idx2 = index(startIndex, offsetBy: min(self.count, range.upperBound))
        return String(self[idx1..<idx2])
    }
}

public struct MoneroAmount: Amount {
    public let currency: Currency = CryptoCurrency.monero
    public let value: UInt64
    
    public init(value: UInt64) {
        self.value = value
    }
    
    public init(from string: String) {
        value = stringToMoneroAmount(string: string)
    }
    
    public func formatted() -> String {
        return moneroAmountToString(amount: value)
    }
}
