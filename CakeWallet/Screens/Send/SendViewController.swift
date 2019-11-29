import UIKit
import CakeWalletLib
import CakeWalletCore
import CWMonero
import QRCodeReader
import SwiftyJSON
import CryptoSwift

protocol QRUri {
    var uri: String { get }
    var amount: Amount? { get }
    var address: String { get }
}

struct MoneroQRResult: QRUri {
    let uri: String
    
    var address: String {
        return self.uri.slice(from: "monero:", to: "?") ?? self.uri
    }
    var amount: Amount? {
        guard let amountStr = self.uri.slice(from: "tx_amount=", to: "&") else {
            return nil
        }
        
        return MoneroAmount(from: amountStr)
    }
    var paymentId: String? {
        return self.uri.slice(from: "tx_payment_id=", to: "&")
    }
    
    init(uri: String) {
        self.uri = uri
    }
}

struct BitcoinQRResult: QRUri {
    let uri: String
    
    var address: String {
        return self.uri.slice(from: "bitcoin:", to: "?") ?? self.uri
    }
    
    var amount: Amount? {
        guard let amount = self.uri.slice(from: "amount=", to: "&") else {
            return nil
        }
        
        return BitcoinAmount(from: amount)
    }
    
    init(uri: String) {
        self.uri = uri
    }
}

struct DefaultCryptoQRResult: QRUri {
    let uri: String
    
    var address: String {
        return self.uri.replacingOccurrences(of: "\(targetDescription):", with: "")
    }
    
    var amount: Amount? {
        return nil
    }
    
    private let target: CryptoCurrency
    private var targetDescription: String {
        switch target {
        case .bitcoin:
            return "bitcoin"
        case .bitcoinCash:
            return "bitcoincash"
        case .dash:
            return "dash"
        case .ethereum:
            return "ethereum"
        case .liteCoin:
            return "litecoin"
        case .monero:
            return "monero"
        case .usdT:
            return "usdtether"
        case .eos:
            return "eos"
        case .xrp:
            return "ripple"
        case .trx:
            return "tron"
        case .bnb:
            return "binancecoin"
        case .ada:
            return "cardano"
        case .xlm:
            return "ripple"
        case .nano:
            return "nano"
        }
    }
    
    init(uri: String, for target: CryptoCurrency) {
        self.uri = uri
        self.target = target
    }
}



final class SendViewController: BaseViewController<SendView>, StoreSubscriber, QRUriUpdateResponsible, QRCodeReaderViewControllerDelegate {
    private static let allSymbol = NSLocalizedString("all", comment: "")
    
    let store: Store<ApplicationState>
    let address: String?
    var priority: TransactionPriority {
        return store.state.settingsState.transactionPriority
    }
    
    private var configuredBalanceDisplay:BalanceDisplay {
        return store.state.settingsState.displayBalance
    }
    
    private weak var alert: UIAlertController?
    private var price: Double {
        return store.state.balanceState.price
    }
    private lazy var paymentIdQRReaderVC: QRCodeReaderViewController = {
        let builder = QRCodeReaderViewControllerBuilder {
            $0.reader = QRCodeReader(metadataObjectTypes: [.qr], captureDevicePosition: .back)
        }
        
        let qrCodeReaderVC = QRCodeReaderViewController(builder: builder)
        qrCodeReaderVC.modalPresentationStyle = .overCurrentContext
        qrCodeReaderVC.delegate = self
        return qrCodeReaderVC
    }()
    
    init(store: Store<ApplicationState>, address: String?) {
        self.store = store
        self.address = address
        super.init()
    }
    
    override func configureBinds() {
        title = NSLocalizedString("send", comment: "")
        modalPresentationStyle = .fullScreen
        contentView.takeFromAddressBookButton.addTarget(self, action: #selector(takeFromAddressBook), for: .touchUpInside)
        contentView.sendAllButton.addTarget(self, action: #selector(setAllAmount), for: .touchUpInside)
        contentView.cryptoAmountTextField.addTarget(self, action: #selector(onCryptoValueChange(_:)), for: .editingChanged)
        contentView.fiatAmountTextField.addTarget(self, action: #selector(onFiatValueChange(_:)), for: .editingChanged)
        contentView.estimatedFeeTitleLabel.text = NSLocalizedString("estimated_fee", comment: "") + ":"
        contentView.addressView.presenter = self
        contentView.addressView.updateResponsible = self
        contentView.scanQrForPaymentId.addTarget(self, action: #selector(scanPaymnetIdQr), for: .touchUpInside)
        updateEstimatedFee(for: store.state.settingsState.transactionPriority)
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(named:"close_symbol")?.resized(to:CGSize(width: 12, height: 12)),
            style: .plain,
            target: self,
            action: #selector(dismissAction)
        )
        
        if let navController = navigationController {
            navController.navigationItem.leftBarButtonItem?.tintColor = UserInterfaceTheme.current.text
            navController.navigationItem.rightBarButtonItem?.tintColor = UserInterfaceTheme.current.text
        }
    }
    
    override func setBarStyle() {
        super.setBarStyle()
        navigationController?.navigationBar.backgroundColor = UserInterfaceTheme.current.sendCardColor
        contentView.backgroundColor = UserInterfaceTheme.current.sendCardColor
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationItem.leftBarButtonItem?.tintColor = UserInterfaceTheme.current.text
        contentView.sendButton.addTarget(self, action: #selector(sendAction), for: .touchUpInside)
        store.subscribe(self, onlyOnChange: [
            \ApplicationState.balanceState,
            \ApplicationState.transactionsState,
            ])
        store.dispatch(
            TransactionsActions.calculateEstimatedFee(
                withPriority: priority
            )
        )
        contentView.addressView.availablePickers = [.qrScan, .addressBook]
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if let address = self.address {
            contentView.addressView.textView.text = address
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        store.dispatch(TransactionsState.Action.changedSendingStage(.none))
        store.unsubscribe(self)
    }
    
    // MARK: StoreSubscriber
    
    func onStateChange(_ state: ApplicationState) {
        updateWallet(name: state.walletState.name)
        updateWallet(type: state.walletState.walletType)
        updateWalletBalance()
        updateSendingStage(state.transactionsState.sendingStage)
        updateFiat(state.settingsState.fiatCurrency)
        updateEstimatedFee(state.transactionsState.estimatedFee)
    }
    
    // MARK: QRUriUpdateResponsible
    
    func updated(_ addressView: AddressView, withURI uri: QRUri) {
        guard let uri = uri as? MoneroQRResult else {
            return
        }
        
        updateAddress(uri.address)
        
        if let amount = uri.amount {
            updateAmount(amount)
        }
        
        updatePaymentId(uri.paymentId)
    }
    
    func getCrypto(for addressView: AddressView) -> CryptoCurrency {
        return .monero
    }
    
    // MARK: QRCodeReaderViewControllerDelegate
    
    func reader(_ reader: QRCodeReaderViewController, didScanResult result: QRCodeReaderResult) {
        let uri = MoneroQRResult(uri: result.value)
        let paymentId = uri.paymentId ?? result.value
        updatePaymentId(paymentId)
        paymentIdQRReaderVC.stopScanning()
        paymentIdQRReaderVC.dismiss(animated: true)
    }
    
    func readerDidCancel(_ reader: QRCodeReaderViewController) {
        reader.stopScanning()
        reader.dismiss(animated: true)
    }
    
    @objc
    private func scanPaymnetIdQr() {
        parent?.present(paymentIdQRReaderVC, animated: true)
    }
    
    @objc
    private func takeFromAddressBook() {
        let addressBookVC = AddressBookViewController(addressBook: AddressBook.shared, store: self.store, isReadOnly: true)
        addressBookVC.doneHandler = { [weak self] address in
            self?.contentView.addressView.textView.text = address
        }
        let sendNavigation = UINavigationController(rootViewController: addressBookVC)
        self.present(sendNavigation, animated: true)
    }
    
    @objc
    private func dismissAction() {
        dismiss(animated: true) { [weak self] in
            self?.onDismissHandler?()
        }
    }
    
    private func updatePaymentId(_ paymentId: String) {
        contentView.paymentIdTextField.text = paymentId
    }
    
    private func updateWallet(name: String) {
        guard name != contentView.cryptoAmountTitleLabel.text else {
            return
        }
        contentView.walletNameLabel.text = name
        contentView.walletNameLabel.flex.markDirty()
        contentView.walletContainer.flex.layout()
        contentView.rootFlexContainer.flex.layout()
    }
    
    private func updateWalletBalance() {
        let newBalanceText = (configuredBalanceDisplay).isHidden == true ? "--" : store.state.balanceState.unlockedBalance.formatted()
        guard newBalanceText != contentView.cryptoAmountTitleLabel.text else {
            return
        }
        contentView.cryptoAmountValueLabel.text = newBalanceText
        contentView.cryptoAmountValueLabel.flex.markDirty()
        contentView.walletContainer.flex.layout()
        contentView.rootFlexContainer.flex.layout()
    }
    
    private func updateWallet(type: WalletType) {
        let title = type.string()
            + " "
            + NSLocalizedString("balance-display-type_unlocked", comment: "")
        guard title != contentView.cryptoAmountTitleLabel.text else {
            return
        }
        contentView.cryptoAmountTitleLabel.text = type.currency.formatted()
            + " "
            + NSLocalizedString("balance-display-type_unlocked", comment: "")
        
        contentView.cryptoAmountTitleLabel.flex.markDirty()
        contentView.walletContainer.flex.markDirty()
        contentView.rootFlexContainer.flex.layout()
    }
    
    private func updateFiat(_ fiat: FiatCurrency) {
        contentView.fiatAmountTextFieldLeftView.text = store.state.settingsState.fiatCurrency.formatted() + ": "
    }
    
    @objc
    private func onCryptoValueChange(_ textField: UITextField) {
        guard
            let fiatValueStr = textField.text?.replacingOccurrences(of: ",", with: "."),
            let fiatValue = Double(fiatValueStr) else {
                contentView.fiatAmountTextField.text = nil
                return
        }
        
        let val = fiatValue * price
        contentView.fiatAmountTextField.text  = String(val)
    }
    
    @objc
    private func onFiatValueChange(_ textField: UITextField) {
        guard
            let cryptoValueStr = textField.text?.replacingOccurrences(of: ",", with: "."),
            let cryptoValue = Double(cryptoValueStr) else {
                contentView.cryptoAmountTextField.text  = nil
                return
        }
        
        let val = cryptoValue / price
        contentView.cryptoAmountTextField.text  = String(format: "%.12f", val)
    }
    
    private func updateSendingStage(_ stage: SendingStage) {
        switch stage {
        case let .pendingTransaction(tx):
            guard let alert = alert else {
                self.onTransactionCreated(tx)
                return
            }
            
            alert.dismiss(animated: true) {
                self.onTransactionCreated(tx)
            }
        case .commited:
            guard let alert = alert else {
                self.onTransactionCommited()
                return
            }
            
            alert.dismiss(animated: true) {
                self.onTransactionCommited()
            }
        default:
            break
        }
    }
    
    private func updateEstimatedFee(_ fee: Amount) {
        let fiatCurrency = store.state.settingsState.fiatCurrency
        let price = store.state.balanceState.price
        let fiatBalance = calculateFiatAmount(fiatCurrency, price: price, balance: fee)
        let formattedFee = MoneroAmountParser.formatValue(fee.value) ?? "0.0"
        let formattedFiat = fiatBalance.formatted()
        contentView.estimatedFeeValueLabel.text = String(format: "%@ (%@)", formattedFee, formattedFiat)
        let estimatedFeeContrinerWidth = contentView.estimatedFeeContriner.frame.size.width
        let totalWidth = estimatedFeeContrinerWidth
        let titleWidth = contentView.estimatedFeeTitleLabel.frame.size.width
        let width = totalWidth - titleWidth

        if width > 0 {
            contentView.estimatedFeeValueLabel.flex.width(width).markDirty()
        } else {
            contentView.estimatedFeeValueLabel.flex.markDirty()
        }
        
        contentView.rootFlexContainer.flex.layout()
    }
    
    private func onTransactionCreated(_ pendingTransaction: PendingTransaction) {
        let confirmController = SendConfirmViewController(amount:pendingTransaction.description.amount.formatted(), address:pendingTransaction.description.id, fee:MoneroAmountParser.formatValue(pendingTransaction.description.fee.value))
        confirmController.modalPresentationStyle = .fullScreen
        confirmController.onAccept = { [weak self] in
            self?.commit(pendingTransaction: pendingTransaction)
        }
        confirmController.onCancel = { [weak self] in
            self?.store.dispatch(
                TransactionsState.Action.changedSendingStage(.none)
            )
        }
        present(confirmController, animated: true)
    }
    
    private func commit(pendingTransaction: PendingTransaction) {
        contentView.sendButton.showLoading()

        let id = pendingTransaction.description.id
        
        store.dispatch(
            WalletActions.commit(
                transaction: pendingTransaction,
                handler: { [weak self] result in
                    DispatchQueue.main.async {
                        self?.contentView.sendButton.hideLoading()
                        
                        switch result {
                        case .success(_):
                            self?.onTransactionCommited()
                            self?.saveRecipientAddress(transactionId: id)
                        case let .failed(error):
                            self?.showErrorAlert(error: error)
                        }
                    }
            })
        )
    }

    private func saveRecipientAddress(transactionId id: String) {
        let address = contentView.addressView.textView.originText.value
        saveRecipientAddress(transactionId: id, address: address)
    }
    
    private func saveRecipientAddress(transactionId id: String, address: String ) {
        if (store.state.settingsState.saveRecipientAddresses) {
            RecipientAddresses.shared.save(forTransactionId: id, andRecipientAddress: address)
        }
    }
    
    private func onTransactionCommited() {
        showOKInfoAlert(title: NSLocalizedString("transaction_created", comment: "")) { [weak self] in
            self?.resetForm()
            self?.dismiss(animated: true)
        }
    }
    
    private func createTransaction(_ handler: (() -> Void)? = nil) {
        let authController = AuthenticationViewController(store: store, authentication: AuthenticationImpl())
        authController.modalPresentationStyle = .fullScreen
        let paymentID = contentView.paymentIdTextField.text  ?? ""
        navigationController?.modalPresentationStyle = .fullScreen
        authController.handler = { [weak self] in
            authController.dismiss(animated: true) {
                self?.contentView.sendButton.showLoading()
                
                let amount = self?.contentView.cryptoAmountTextField.text == SendViewController.allSymbol
                    ? nil
                    : MoneroAmount(from: self!.contentView.cryptoAmountTextField.text?.replacingOccurrences(of: ",", with: ".") ?? "0.0")
                let address = self?.contentView.addressView.textView.originText.value ?? ""
                guard let priority = self?.priority else { return }
                
                self?.store.dispatch(
                    WalletActions.send(
                        amount: amount,
                        toAddres: address,
                        paymentID: paymentID,
                        priority: priority,
                        handler: { [weak self] res in
                            DispatchQueue.main.async {
                                self?.contentView.sendButton.hideLoading()
                                
                                switch res {
                                case let .success(pendingTransaction):
                                    self?.onTransactionCreated(pendingTransaction)
                                case let .failed(error):
                                    self?.showErrorAlert(error: error)
                                }
                            }
                        }
                    )
                )
            }
        }
        
        present(authController, animated: true)
    }
    
    private func resetForm() {
        contentView.fiatAmountTextField.text  = ""
        contentView.cryptoAmountTextField.text  = ""
        contentView.addressView.textView.text = ""
        store.dispatch(TransactionsState.Action.changedSendingStage(.none))
    }
    
    @objc
    private func sendAction() {
        createTransaction()
    }
    
    @objc
    private func setAllAmount() {
        contentView.cryptoAmountTextField.text  = SendViewController.allSymbol
    }
    
    private func updateAmount(_ amount: Amount) {
        contentView.cryptoAmountTextField.text  = amount.formatted()
    }
    
    private func updatePaymentId(_ paymentId: String?) {
        contentView.paymentIdTextField.text  = paymentId
    }
    
    private func updateAddress(_ address: String) {
        contentView.addressView.textView.text = address
    }
    
    private func updateEstimatedFee(for priority: TransactionPriority) {
        contentView.estimatedDescriptionLabel.text = NSLocalizedString("Currently the fee is set at", comment: "")
            + " "
            + priority.formatted()
            + " "
            + NSLocalizedString("priority", comment: "")
            + ". "
            + NSLocalizedString("Transaction priority can be adjusted in the settings", comment: "")
    }
}

