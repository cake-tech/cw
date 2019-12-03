import Foundation

public protocol Formatted {
    func formatted() -> String
}

public protocol LocalizedFormat: Formatted {
    func localizedString() -> String
}

extension LocalizedFormat {
    public func localizedString() -> String {
        return NSLocalizedString(self.formatted(), comment:"")
    }
}

public enum BalanceDisplay: Int, LocalizedFormat {
    public static var all: [BalanceDisplay] {
        return [.full, .unlocked, .hidden]
    }
    
    public var rawValue: Int {
        switch self {
        case .full:
            return 3
        case .unlocked:
            return 2
        case .hidden:
            return 1
        }
    }
    
    public var isHidden: Bool {
        switch self {
        case .hidden:
            return true
        default:
            return false
        }
    }
    
    case full, unlocked, hidden
    
    public init?(from raw:Int) {
        switch raw {
        case 3:
            self = .full
        case 2:
            self = .unlocked
        case 1:
            self = .hidden
            
        default:
            return nil
        }
    }
    
    public func formatted() -> String {
        switch self {
        case .full:
            return "balance-display-type_full"
        case .unlocked:
            return "balance-display-type_unlocked"
        case .hidden:
            return "balance-display-type_hidden"
        }
    }
}

public protocol Currency: Formatted {}

public protocol Amount: Formatted {
    var currency: Currency { get }
    var value: UInt64 { get }
}

extension Amount {
    public func compare(with amount: Amount) -> Bool {
        return type(of: amount) == type(of: self) && amount.value == self.value
    }
}

public enum CryptoCurrency: Currency {
    public static var all: [CryptoCurrency] {
        var all:[CryptoCurrency] = [.bitcoin, .ethereum, .liteCoin, .bitcoinCash, .dash, .usdT, .eos, .xrp, .trx, .bnb, .ada, .xlm, .nano].sorted(by: { $0.formatted() < $1.formatted() })
        all.insert(.monero, at:0)
        return all
    }
    
    case monero, bitcoin, ethereum, dash, liteCoin, bitcoinCash, usdT, eos, xrp, trx, bnb, ada, xlm, nano
    
    public init?(from string: String) {
        switch string.uppercased() {
        case "XMR":
            self = .monero
        case "BTC":
            self = .bitcoin
        case "ETH":
            self = .ethereum
        case "DASH":
            self = .dash
        case "LTC":
            self = .liteCoin
        case "BCH":
            self = .bitcoinCash
        case "USDT":
            self = .usdT
        case "EOS":
            self = .eos
        case "XRP":
            self = .xrp
        case "TRX":
            self = .trx
        case "BNB":
            self = .bnb
        case "ADA":
            self = .ada
        case "XLM":
            self = .xlm
        case "NANO":
            self = .nano
        default:
            return nil
        }
    }
    
    public func formatted() -> String {
        switch self {
        case .monero:
            return "XMR"
        case .bitcoin:
            return "BTC"
        case .ethereum:
            return "ETH"
        case .dash:
            return "DASH"
        case .liteCoin:
            return "LTC"
        case .bitcoinCash:
            return "BCH"
        case .usdT:
            return "USDT"
        case .eos:
            return "EOS"
        case .xrp:
            return "XRP"
        case .trx:
            return "TRX"
        case .bnb:
            return "BNB"
        case .ada:
            return "ADA"
        case .xlm:
            return "XLM"
        case .nano:
            return "NANO"
        }
    }
}

public enum FiatCurrency: Int, Currency {
    public static var all: [FiatCurrency] {
        return [.aud, .bgn, .brl, .cad, .chf, .cny, .czk, .eur, .dkk, .gbp, .hkd, .hrk, .huf, .idr, .ils, .inr, .isk, .jpy, .krw, .mxn, .myr, .nok, .nzd, .php, .pln, .ron, .rub, .sek, .sgd, .thb, .`try`, .usd, .zar, .vef]
    }
    
    case aud, bgn, brl, cad, chf, cny, czk, eur, dkk, gbp, hkd, hrk, huf, idr, ils, inr, isk, jpy, krw, mxn, myr, nok, nzd, php, pln, ron, rub, sek, sgd, thb, `try`, usd, zar, vef
    
    public func formatted() -> String {
        switch self {
        case .aud:
            return "AUD"
        case .bgn:
            return "BGN"
        case .brl:
            return "BRL"
        case .cad:
            return "CAD"
        case .chf:
            return "CHF"
        case .cny:
            return "CNY"
        case .czk:
            return "CZK"
        case .eur:
            return "EUR"
        case .dkk:
            return "DKK"
        case .gbp:
            return "GBP"
        case .hkd:
            return "HKD"
        case .hrk:
            return "HRK"
        case .huf:
            return "HUF"
        case .idr:
            return "IDR"
        case .ils:
            return "ILS"
        case .inr:
            return "INR"
        case .isk:
            return "ISK"
        case .jpy:
            return "JPY"
        case .krw:
            return "KRW"
        case .mxn:
            return "MXN"
        case .myr:
            return "MYR"
        case .nok:
            return "NOK"
        case .nzd:
            return "NZD"
        case .php:
            return "PHP"
        case .pln:
            return "PLN"
        case .ron:
            return "RON"
        case .rub:
            return "RUB"
        case .sek:
            return "SEK"
        case .sgd:
            return "SGB"
        case .thb:
            return "THB"
        case .try:
            return "TRY"
        case .usd:
            return "USD"
        case .zar:
            return "ZAR"
        case .vef:
            return "VEF"
        }
    }
}
