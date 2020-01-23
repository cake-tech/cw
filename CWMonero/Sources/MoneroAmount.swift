import CakeWalletLib

extension String {
    subscript(_ range: CountableRange<Int>) -> String {
        let idx1 = index(startIndex, offsetBy: max(0, range.lowerBound))
        let idx2 = index(startIndex, offsetBy: min(self.count, range.upperBound))
        return String(self[idx1..<idx2])
    }
}

fileprivate let nf = NumberFormatter()

public struct MoneroAmount: Amount {
    public let currency: Currency = CryptoCurrency.monero
    public let value: UInt64
    fileprivate let nf:NumberFormatter
    
    public init(value: UInt64) {
        self.value = value
        nf = NumberFormatter()
        nf.numberStyle = .decimal
        nf.maximumFractionDigits = 1000000000000
        nf.minimumFractionDigits = 1
    }
    
    public init(from string: String) {
        var _string = string
        let splitResult = string.split(separator: ".")

        if splitResult.count > 1 {
            let afterDot = splitResult[1]

            if afterDot.count > 12 {
                let forCut = String(afterDot)
                let cut = String(forCut[0..<12])
                let beforeDot = String(splitResult[0])
                _string = String(format: "%@.%@", beforeDot, cut)
            }
        }
        
        value = MoneroAmountParser.amount(from: _string)
        
        nf = NumberFormatter()
        nf.numberStyle = .decimal
        nf.maximumFractionDigits = 1000000000000
        nf.minimumFractionDigits = 1
    }
    
    public func formatted() -> String {
        guard
            let formattedValue = MoneroAmountParser.formatValue(value),
            let _value = Double(formattedValue),
            _value != 0 else {
              return "0.0"
        }
        let number = NSNumber(value:_value)
        return nf.string(from:number) ?? String(_value)
    }
}
