import UIKit


final class TradeDetailsViewController: BaseViewController<TransactionDetailsView>, UITableViewDataSource, UITableViewDelegate {
    private(set) var items: [TradeDetailsCellItem] = []
    private let trade: TradeInfo
    
    init(trade: TradeInfo) {
        self.trade = trade
        super.init()
    }
    
    override func configureBinds() {
        title = "Trade details"
        let backButton = UIBarButtonItem(title: "", style: .plain, target: self, action: nil)
        navigationItem.backBarButtonItem = backButton
        
        contentView.table.dataSource = self
        contentView.table.delegate = self
        contentView.table.register(items: [TradeDetailsCellItem.self])
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        update(trade: trade)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = items[indexPath.row]
        return tableView.dequeueReusableCell(withItem: item, for: indexPath)
    }
    
    private func update(trade: TradeInfo) {
        items.append(TradeDetailsCellItem(row: .tradeID, value: trade.tradeID))
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM d, yyyy HH:mm"
        let formattedDate = dateFormatter.string(from: Date(timeIntervalSince1970: trade.date))
        items.append(TradeDetailsCellItem(row: .date, value: formattedDate))
        
        items.append(TradeDetailsCellItem(row: .exchangeProvider, value: trade.provider))
    }
    
    @objc
    private func dismissAction() {
        dismiss(animated: true) { [weak self] in
            self?.onDismissHandler?()
        }
    }
}
