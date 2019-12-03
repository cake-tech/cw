import UIKit
import CakeWalletLib
import CWMonero

final class TransactionDetailsViewController: BaseViewController<TransactionDetailsView>, UITableViewDataSource, UITableViewDelegate {
    var exchangeFlow: ExchangeFlow?
    private static let emptyPaymentId = "0000000000000000"
    private(set) var items: [TransactionDetailsCellItem]
    private let transactionDescription: TransactionDescription

    init(transactionDescription: TransactionDescription) {
        self.transactionDescription = transactionDescription
        items = []
        super.init()
    }
    
    override func configureBinds() {
        title = NSLocalizedString("transaction_details", comment: "")
        let backButton = UIBarButtonItem(title: "", style: .plain, target: self, action: nil)
        navigationItem.backBarButtonItem = backButton
        contentView.table.dataSource = self
        contentView.table.delegate = self
        contentView.table.separatorStyle = .singleLine
        contentView.table.separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        contentView.table.separatorColor = UserInterfaceTheme.current.gray.dim
        contentView.table.register(items: [TransactionDetailsCellItem.self])
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(named:"close_symbol")?.resized(to:CGSize(width: 12, height: 12)),
            style: .plain,
            target: self,
            action: #selector(dismissAction)
        )
        update(transactionDescription: transactionDescription)
    }
    
    // MARK: UITableViewDataSource
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = items[indexPath.row]
        return tableView.dequeueReusableCell(withItem: item, for: indexPath)
    }
    
    func tableView(_ tableView: UITableView, shouldShowMenuForRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, canPerformAction action: Selector, forRowAt indexPath: IndexPath, withSender sender: Any?) -> Bool {
        if (action == #selector(UIResponderStandardEditActions.copy(_:))) {
            return true
        }
        
        return false
    }
    
    func tableView(_ tableView: UITableView, performAction action: Selector, forRowAt indexPath: IndexPath, withSender sender: Any?) {
        let item = items[indexPath.row]
        UIPasteboard.general.string = item.value
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let item = items[indexPath.row]
        
        if item.row == .exchangeID {
            showTradeDetails()
        }
    }
    
    func showTradeDetails() {
        if let expectedTradeInfoJSON = ExchangeTransactions.shared.getTradeByTransactionID(by: transactionDescription.id) {
            let tradeInfo = TradeInfo(json: expectedTradeInfoJSON)
            
            if (tradeInfo.provider.count != 0) {
                exchangeFlow?.change(route: .tradeDetails(tradeInfo))
                return
            }
            
            presentExchangeProviderSelection(tradeInfo: tradeInfo)
        }
    }
    
    func presentExchangeProviderSelection(tradeInfo: TradeInfo) {
        let pickerVC = PickerViewController(items: ExchangeProvider.allCases, selectedItem: .xmrto)
        
        pickerVC.pickerTitle = "Select exchange provider"
        pickerVC.onPick = { [weak self] provider in
            pickerVC.onDismissHandler = {
                var withProvider = tradeInfo
                withProvider.provider = provider.rawValue
                
                self?.exchangeFlow?.change(route: .tradeDetails(withProvider))
            }
        }
        
        pickerVC.modalPresentationStyle = .overFullScreen
        present(pickerVC, animated: true)
    }
    
    private func update(transactionDescription: TransactionDescription) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM d, yyyy HH:mm"
        
        items = [TransactionDetailsCellItem(row: .id, value: transactionDescription.id)]
        
        if !transactionDescription.paymentId.isEmpty && transactionDescription.paymentId != TransactionDetailsViewController.emptyPaymentId {
            items.append(TransactionDetailsCellItem(row: .paymentId, value: transactionDescription.paymentId))
        }
        
        let subaddresses = transactionDescription.subaddresses()
            .map({ $0.label })
            .joined(separator: ",")
        
        items.append(contentsOf: [
            TransactionDetailsCellItem(row: .date, value: dateFormatter.string(from: transactionDescription.date)),
            TransactionDetailsCellItem(row: .height, value: String(transactionDescription.height)),
            TransactionDetailsCellItem(row: .amount, value: transactionDescription.totalAmount.formatted())])
        
        if store.state.settingsState.saveRecipientAddresses, let recipientAddress = transactionDescription.recipientAddress() {
            items.append(TransactionDetailsCellItem(row: .recipientAddress, value: recipientAddress))
        }
        
        if !subaddresses.isEmpty {
            items.append(TransactionDetailsCellItem(row: .subaddresses, value:  subaddresses))
        }
        
        let fee = MoneroAmountParser.formatValue(transactionDescription.fee.value) ?? "0.0"

        if !fee.isEmpty {
            items.append(TransactionDetailsCellItem(row: .fee, value: fee))
        }
        
        if let tradeID = transactionDescription.tradeId() {
            var value = ""
            
            if let exchangeProvider = transactionDescription.exchangeProvider() {
                value += exchangeProvider.uppercased() + ": "
            }
            
            value += tradeID
            
            items.append(TransactionDetailsCellItem(row: .exchangeID, value: value))
        }
        
        if let transactionKey = getTransactionKey(for: transactionDescription.id), !transactionKey.isEmpty {
            items.append(TransactionDetailsCellItem(row: .transactionKey , value: transactionKey))
        }
        
        contentView.table.reloadData()
        contentView.rootFlexContainer.flex.layout(mode: .adjustHeight)
        contentView.table.isScrollEnabled = contentView.table.contentSize.height > contentView.table.frame.size.height
    }
    
    @objc
    private func dismissAction() {
        dismiss(animated: true) { [weak self] in
            self?.onDismissHandler?()
        }
    }
}

