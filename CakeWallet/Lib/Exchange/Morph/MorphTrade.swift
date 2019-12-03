import Foundation
import CakeWalletLib
import RxSwift
import Alamofire
import SwiftyJSON

struct MorphTrade: Trade {
    static func findBy(id: String) -> Observable<Trade> {
        return Observable.create({ o -> Disposable in
            exchangeQueue.async {
                let url =  URLComponents(string: "\(MorphExchange.morphTokenUri)/morph/\(id)")!
                var request = URLRequest(url: url.url!)
                request.addValue("application/json", forHTTPHeaderField: "Content-Type")
                
                Alamofire.request(request).responseData(completionHandler: { response in
                    if let error = response.error {
                        o.onError(error)
                        return
                    }
                    
                    guard
                        let data = response.data,
                        let json = try? JSON(data: data),
                        let stateString = json["state"].string,
                        let state = ExchangeTradeState(rawValue: stateString.lowercased()) else {
                            o.onError(ExchangerError.tradeNotFould(id))
                            return
                    }

                    let toRaw = json["output"].arrayValue.first!["asset"].stringValue
                    let from = CryptoCurrency(from: json["input"]["asset"].stringValue)!
                    let to = CryptoCurrency(from: toRaw)!
                    let inputAddress = json["input"]["deposit_address"].stringValue
                    let outputAddress = json["output"].arrayValue.first!["address"].stringValue
                    let min = makeAmount(json["input"]["limits"]["min"].doubleValue, currency: from)
                    let max = makeAmount(json["input"]["limits"]["max"].doubleValue, currency: from)
                    
                    let trade = MorphTrade(
                        id: id,
                        from: from,
                        to: to,
                        inputAddress: inputAddress,
                        outputAdress: outputAddress,
                        amount: makeAmount(0.0, currency: from),
                        min: min,
                        max: max,
                        state: state,
                        extraId: nil,
                        provider: .morph,
                        outputTransaction: nil)
                    o.onNext(trade)
                })
            }
            return Disposables.create()
        })
    }
    
    let id: String
    let from: CryptoCurrency
    let to: CryptoCurrency
    let inputAddress: String
    let outputAdress: String
    let amount: Amount
    let min: Amount
    let max: Amount
    let state: ExchangeTradeState
    let extraId: String?
    let provider: ExchangeProvider
    let outputTransaction: String?
    
    func update() -> Observable<Trade> {
        return MorphTrade.findBy(id: id)
            .map({ $0 as! MorphTrade })
            .map({ MorphTrade(
                id: self.id,
                from: $0.from,
                to: $0.to,
                inputAddress: $0.inputAddress,
                outputAdress: $0.outputAdress,
                amount: self.amount,
                min: $0.min,
                max: $0.max,
                state: $0.state,
                extraId: $0.extraId,
                provider: $0.provider,
                outputTransaction: $0.outputTransaction) })
    }
}
