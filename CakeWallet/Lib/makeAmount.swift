import Foundation
import CakeWalletLib
import CWMonero

func makeAmount(_ amount: Double, currency: CryptoCurrency) -> Amount {
    let outputAmount: Amount
    let amount = String(amount)
    
    switch currency {
    case .bitcoin:
        outputAmount = BitcoinAmount(from: amount)
    case .monero:
        outputAmount = MoneroAmount(from: amount)
    case .ethereum:
        outputAmount = EthereumAmount(from: amount)
    default:
        outputAmount = EDAmount(from: amount, currency: currency)
    }
    
    return outputAmount
}

func makeAmount(_ amount: String, currency: CryptoCurrency) -> Amount {
    let outputAmount: Amount
    
    switch currency {
    case .bitcoin:
        outputAmount = BitcoinAmount(from: amount)
    case .monero:
        outputAmount = MoneroAmount(from: amount)
    case .ethereum:
        outputAmount = EthereumAmount(from: amount)
    default:
        outputAmount = EDAmount(from: amount, currency: currency)
    }
    
    return outputAmount
}

func makeAmount(_ value: UInt64, currency: CryptoCurrency) -> Amount {
    switch currency {
    case .bitcoin:
        return BitcoinAmount(value: value)
    case .ethereum:
        return EthereumAmount(value: value)
    case .monero:
        return MoneroAmount(value: value)
    default:
        return EDAmount(value: value, currency: currency)
    }
}
