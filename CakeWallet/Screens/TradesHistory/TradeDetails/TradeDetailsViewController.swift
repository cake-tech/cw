import UIKit
import Alamofire
import SwiftyJSON
import CWMonero
import CakeWalletLib
import RxSwift
import RxBiBinding
import RxCocoa

final class TradeDetailsViewController: BaseViewController<TransactionDetailsView>, UITableViewDataSource, UITableViewDelegate {
    private(set) var items: [TradeDetailsCellItem] = []
    private let trade: TradeInfo
    private var tradeDetails: BehaviorRelay<Trade?>
    private lazy var updateTradeStateTimer: Timer = {
        return Timer.scheduledTimer(withTimeInterval: 10, repeats: true) { [weak self] timer in
            self?.updateTradeDetails()
        }
    }()
    
    private let disposeBag: DisposeBag
    
    init(trade: TradeInfo) {
        self.trade = trade
        tradeDetails = BehaviorRelay(value: nil)
        disposeBag = DisposeBag()
        super.init()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateTradeDetails()
        setRows(trade: trade)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        fetchTradeDetails()
    }
    
    override func configureBinds() {
        title = "Trade details"
        let backButton = UIBarButtonItem(title: "", style: .plain, target: self, action: nil)
        navigationItem.backBarButtonItem = backButton
        
        contentView.table.dataSource = self
        contentView.table.delegate = self
        contentView.table.register(items: [TradeDetailsCellItem.self])
        
        updateTradeStateTimer.fire()
        
        let tradeObserver = tradeDetails.asObservable()
        tradeObserver.subscribe(onNext: { [weak self] trade in
            if let this = self,
                let trade = trade {
                let itemsWithUpdatedStateInfo = this.items.map{ (i) -> TradeDetailsCellItem in
                    if i.row == .state {
                        return TradeDetailsCellItem(row: .state, value: trade.state.formatted())
                    }
                    
                    return i
                }

                this.items = itemsWithUpdatedStateInfo
                this.contentView.table.reloadData()
            }
        }).disposed(by: disposeBag)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = items[indexPath.row]
        return tableView.dequeueReusableCell(withItem: item, for: indexPath)
    }
    
    private func setRows(trade: TradeInfo) {
        items.append(TradeDetailsCellItem(row: .tradeID, value: trade.tradeID))
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM d, yyyy HH:mm"
        let formattedDate = dateFormatter.string(from: Date(timeIntervalSince1970: trade.date))
        items.append(TradeDetailsCellItem(row: .date, value: formattedDate))
        
        items.append(TradeDetailsCellItem(row: .exchangeProvider, value: trade.provider))
        
        items.append(TradeDetailsCellItem(row: .state, value: "Fetching..."))
    }
    
    private func fetchTradeDetails() {
        let url = URLComponents(string: String(format: "%@/order_status_query/", XMRTOExchange.uri))!
        var request = URLRequest(url: url.url!)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("CakeWallet/XMR iOS", forHTTPHeaderField: "User-Agent")
        let bodyJSON: JSON = [
            "uuid": trade.tradeID
        ]
        
        try? request.httpBody = try bodyJSON.rawData(options: .prettyPrinted)
        
        Alamofire.request(request).responseData(completionHandler: { [weak self] response in
            guard response.response?.statusCode == 200 else {
                return
            }
            
            guard
                let data = response.data,
                let json = try? JSON(data: data) else {
                    return
            }
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
            
            let address = json["xmr_receiving_integrated_address"].stringValue
            let paymentId = json["xmr_required_payment_id_short"].stringValue
            let totalAmount = json["xmr_amount_total"].stringValue
            let amount = MoneroAmount(from: totalAmount)
            let stateString = json["state"].stringValue
            let state = ExchangeTradeState(fromXMRTO: stateString) ?? .notFound
            let expiredAt = dateFormatter.date(from: json["expires_at"].stringValue)
            let outputTransaction = json["btc_transaction_id"].string
            
            if let this = self {
                let tradeDetails = XMRTOTrade(
                    id: this.trade.tradeID,
                    from: CryptoCurrency.monero,
                    to: CryptoCurrency.bitcoin,
                    state: state,
                    inputAddress: address,
                    amount: amount,
                    extraId: paymentId,
                    expiredAt: expiredAt,
                    outputTransaction: outputTransaction)
                
                this.tradeDetails.accept(tradeDetails)
            }
        })
    }
    
    private func updateTradeDetails() {
        if let val = tradeDetails.value {
            val.update().bind(to: tradeDetails).disposed(by: disposeBag)
        }
    }
    
    @objc
    private func dismissAction() {
        dismiss(animated: true) { [weak self] in
            self?.onDismissHandler?()
        }
    }
}
