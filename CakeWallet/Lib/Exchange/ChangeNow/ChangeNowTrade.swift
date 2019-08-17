import Foundation
import CakeWalletLib
import CWMonero
import SwiftyJSON
import Alamofire
import RxSwift

struct ChangeNowTrade: Trade {
    let id: String
    let from: CryptoCurrency
    let to: CryptoCurrency
    let inputAddress: String
    let amount: Amount
    let payoutAddress: String
    let refundAddress: String?
    let state: ExchangeTradeState
    let extraId: String?
    let provider: ExchangeProvider = .changenow
    let outputTransaction: String?
    
    static func findBy(id: String) -> Observable<Trade> {
        return Observable.create({ o -> Disposable in
            exchangeQueue.async {
                let url = "\(ChangeNowExchange.uri)transactions/\(id)/\(ChangeNowExchange.apiKey)"
                
                Alamofire.request(url).responseData(completionHandler: { response in
                    if let error = response.error {
                        o.onError(error)
                        return
                    }
                    
                    guard let data = response.data else {
                        return
                    }
                    
                    do {
                        let json = try JSON(data: data)
                        let state = ExchangeTradeState(fromChangenow: json["status"].stringValue) ?? .created
                        let from = CryptoCurrency(from: json["fromCurrency"].stringValue)!
                        let to = CryptoCurrency(from: json["toCurrency"].stringValue)!
                        let amount = makeAmount(json["amountSend"].stringValue, currency: from)
                        
                        let trade = ChangeNowTrade(
                            id: id,
                            from: from,
                            to: to,
                            inputAddress: json["payinAddress"].stringValue,
                            amount: amount,
                            payoutAddress: json["payoutAddress"].stringValue,
                            refundAddress: nil,
                            state: state,
                            extraId: json["payinExtraId"].string,
                            outputTransaction: json["payoutHash"].string)
                        o.onNext(trade)
                    } catch {
                        o.onError(error)
                    }
                    
                })
            }
            
            return Disposables.create()
        })
    }
    
    func update() -> Observable<Trade> {
        return ChangeNowTrade.findBy(id: id)
            .map({ $0 as! ChangeNowTrade })
            .map({
                ChangeNowTrade(
                    id: $0.id,
                    from: $0.from,
                    to: $0.to,
                    inputAddress: $0.inputAddress,
                    amount: self.amount,
                    payoutAddress: $0.payoutAddress,
                    refundAddress: self.refundAddress,
                    state: $0.state,
                    extraId: $0.extraId,
                    outputTransaction: $0.outputTransaction) })
    }
}
