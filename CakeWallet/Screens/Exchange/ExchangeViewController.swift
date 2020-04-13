import UIKit
import CakeWalletLib
import CakeWalletCore
import FlexLayout
import SwiftyJSON
import Alamofire
import CWMonero
import RxSwift
import RxCocoa
import RxBiBinding
import SwiftSVG

private let morphTokenUri = "https://api.morphtoken.com"
private let xmrtoUri = "https://xmr.to/api/v2/xmr2btc"
private let cakeUserAgent = "CakeWallet/XMR iOS"

struct ExchangeOutput {
    let address: String
    let weight: Int
    let crypto: CryptoCurrency
}

public enum ExchangeTradeState: String, Formatted {
    case pending, confirming, processing, trading, traded, complete
    case toBeCreated, unpaid, underpaid, paidUnconfirmed, paid, btcSent, timeout, notFound
    case created, finished
    
    init?(fromChangenow value: String) {
        let _value = value.lowercased()
        
        switch _value {
        case "finished":
            self = .finished
        case "created":
            self = .created
        default:
            return nil
        }
    }
    
    init?(fromXMRTO value: String) {
        let _value = value.uppercased()
        
        switch _value {
        case "TO_BE_CREATED":
            self = .toBeCreated
        case "UNPAID":
            self = .unpaid
        case "UNDERPAID":
            self = .underpaid
        case "PAID_UNCONFIRMED":
            self = .paidUnconfirmed
        case "PAID":
            self = .paid
        case "BTC_SENT":
            self = .btcSent
        case "TIMED_OUT":
            self = .timeout
        case "NOT_FOUND":
            self = .notFound
        default:
            return nil
        }
    }
    
    public func formatted() -> String {
        switch self {
        case .toBeCreated:
            return "To be created"
        case .unpaid:
            return "Unpaid"
        case .underpaid:
            return "Under paid"
        case .paidUnconfirmed:
            return "Paid unconfirmed"
        case .paid:
            return "Paid"
        case .btcSent:
            return "BTC sent"
        case .timeout:
            return "Time out"
        case .notFound:
            return "Not found"
        case .finished:
            return "Finished"
        case .created:
            return "Created"
        default:
            let prefix = "exchange_trade_state_"
            return NSLocalizedString(prefix + self.rawValue, comment: "")
        }
    }
}

public enum ExchangeProvider: String, CaseIterable {
    case morph, xmrto, changenow
    
    func iconName() -> String {
        switch self {
        case .morph:
            return "morphtoken_logo"
        case .xmrto:
            return "xmr_to_logo"
        case .changenow:
            return "cn_logo"
        }
    }
}

extension ExchangeProvider: Formatted {
    public func formatted() -> String {
        switch self {
        case .morph:
            return "Morph"
        case .xmrto:
            return "XMR.TO"
        case .changenow:
            return "ChangeNow"
        }
    }
}

public struct ExchangeTrade: Equatable {
    public static func == (lhs: ExchangeTrade, rhs: ExchangeTrade) -> Bool {
        return lhs.id == rhs.id
            && lhs.inputCurrency == rhs.inputCurrency
            && lhs.outputCurrency == rhs.outputCurrency
            && lhs.inputAddress == rhs.inputAddress
            && lhs.min.compare(with: rhs.min)
            && lhs.max.compare(with: rhs.max)
            && lhs.status == rhs.status
            && lhs.provider == rhs.provider
            && lhs.timeout == rhs.timeout
    }
    
    public let id: String
    public let inputCurrency: CryptoCurrency
    public let outputCurrency: CryptoCurrency
    public let inputAddress: String
    public let min: Amount
    public let max: Amount
    public let value: Amount?
    public let status: ExchangeTradeState
    public let paymentId: String?
    public let provider: ExchangeProvider
    public let timeout: Int?
    public let outputTxID: String?
    public let createdAt: Date?
    public let expiredAt: Date?
    
    public init(
        id: String,
        inputCurrency: CryptoCurrency,
        outputCurrency: CryptoCurrency,
        inputAddress: String,
        min: Amount,
        max: Amount,
        value: Amount? = nil,
        status: ExchangeTradeState,
        paymentId: String? = nil,
        provider: ExchangeProvider,
        timeout: Int? = nil,
        outputTxID: String? = nil,
        createdAt: Date? = nil,
        expiredAt: Date? = nil) {
        self.id = id
        self.inputCurrency = inputCurrency
        self.outputCurrency = outputCurrency
        self.inputAddress = inputAddress
        self.min = min
        self.max = max
        self.value = value
        self.status = status
        self.paymentId = paymentId
        self.provider = provider
        self.timeout = timeout
        self.outputTxID = outputTxID
        self.createdAt = createdAt
        self.expiredAt = expiredAt
    }
}

enum ExchangerError: Error {
    case credentialsFailed(String)
    case tradeNotFould(String)
    case limitsNotFoud
    case tradeNotCreated
    case incorrectOutputAddress
    case notCreated(String)
    case amountIsOverMaxLimit
    case amountIsLessMinLimit
}

extension ExchangerError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case let .credentialsFailed(reason):
            return reason
        case .tradeNotFould(_):
            return NSLocalizedString("trade_not_found", comment: "")
        case .limitsNotFoud:
            return "" // fix me
        case .tradeNotCreated:
            return "Trade not created"
        case .incorrectOutputAddress:
            return "Inccorrect output address"
        case let .notCreated(description):
            return description
        case .amountIsOverMaxLimit:
            return "Amount is over the maximum limit"
        case .amountIsLessMinLimit:
            return "Amount is below the minimum limit"
        }
    }
}

extension Array {
    public func toDictionary<Key: Hashable>(with selectKey: (Element) -> Key) -> [Key:Element] {
        var dict = [Key:Element]()
        for element in self {
            dict[selectKey(element)] = element
        }
        return dict
    }
}

typealias Limits = (min: UInt64, max: UInt64)

private func fetchLimits(for inputAsset: CryptoCurrency, and outputAsset: CryptoCurrency, outputWeight: Int = 10000, handler: @escaping (CakeWalletLib.Result<Limits>) -> Void) {
    exchangeQueue.async {
        let url =  URLComponents(string: "\(morphTokenUri)/limits")!
        var request = URLRequest(url: url.url!)
        request.httpMethod = "POST"
        let intput: JSON = ["asset": inputAsset.formatted()]
        let output: JSON = ["asset": outputAsset.formatted(), "weight": outputWeight]
        let body: JSON = [
            "input" : intput,
            "output" : [output]
        ]
        request.httpBody = try? body.rawData()
        
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        Alamofire.request(request).responseData(completionHandler: { response in
            if let error = response.error {
                handler(.failed(error))
                return
            }
            
            guard
                let data = response.data,
                let json = try? JSON(data: data) else {
                    return
            }
            
            if
                let success = json["success"].bool,
                !success {
                handler(.failed(ExchangerError.limitsNotFoud))
                return
            }
            
            guard
                let min = json["input"]["limits"]["min"].uInt64,
                let max = json["input"]["limits"]["max"].uInt64
                else {
                    handler(.failed(ExchangerError.limitsNotFoud))
                    return
                    
            }
            
            let limits = Limits(min: min, max: max)
            handler(.success(limits))
        })
    }
}

private func fetchXMRTOLimits(handler: @escaping (CakeWalletLib.Result<(min: Double, max: Double)>) -> Void) {
    exchangeQueue.async {
        let url =  URLComponents(string: "\(xmrtoUri)/order_parameter_query")!
        var request = URLRequest(url: url.url!)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        Alamofire.request(request).responseData(completionHandler: { response in
            if let error = response.error {
                handler(.failed(error))
                return
            }
            
            guard
                let data = response.data,
                let json = try? JSON(data: data) else {
                    return
            }
            
            guard
                let min = json["lower_limit"].double,
                let max = json["upper_limit"].double
                else {
                    handler(.failed(ExchangerError.limitsNotFoud))
                    return
            }
            
            let limits = (min: min, max: max)
            handler(.success(limits))
        })
    }
}


final class ExchangeViewController: BaseViewController<ExchangeView>, StoreSubscriber, CurrencyPickerDelegate {
    weak var exchangeFlow: ExchangeFlow?
    
    let cryptos: [CryptoCurrency]
    let store: Store<ApplicationState>
    
    var depositAmount: Amount {
        let stringAmount = contentView.depositCardView.amountTextField.text?.replacingOccurrences(of: ",", with: ".") ?? ""
        return makeAmount(stringAmount, currency: depositCrypto.value)
    }
    
    private var receiveAmount: Amount {
        get {
            let stringAmount = contentView.receiveCardView.amountTextField.text?.replacingOccurrences(of: ",", with: ".") ?? ""
            return makeAmount(stringAmount, currency: receiveCrypto.value)
        }
        
        set {
            contentView.receiveCardView.amountTextField.text = newValue.formatted()
        }
    }
    
    private let receiveAmountString: BehaviorRelay<String>
    private let depositAmountString: BehaviorRelay<String>
    private let receiveAddress: BehaviorRelay<String>
    private let depositRefundAddress: BehaviorRelay<String>
    private let depositMinAmount: BehaviorRelay<String>
    private let depositMaxAmount: BehaviorRelay<String>
    private let receiveMinAmount: BehaviorRelay<String>
    private let receiveMaxAmount: BehaviorRelay<String>
    
    private let depositCrypto: BehaviorRelay<CryptoCurrency>
    private let receiveCrypto: BehaviorRelay<CryptoCurrency>
    
    private var didSetCurrentAddressForDeposit: Bool
    private var didSetCurrentAddressForReceive: Bool
    private var exchangeNameView: ExchangeNameView = ExchangeNameView()
    
    private var exchange: AnyExchange = XMRTOExchange() {
        didSet {
            exchangeChanged()
        }
    }
    private let exchangeList: ExchangeList = ExchangeList()
    private let receiveLimits: BehaviorRelay<ExchangeLimits> = BehaviorRelay(value: (min: nil, max: nil))
    private let depositLimits: BehaviorRelay<ExchangeLimits> = BehaviorRelay(value: (min: nil, max: nil))
    private let disposeBag: DisposeBag
    
    private var depositCurrencyDisplayed:CryptoCurrency = CryptoCurrency.bitcoinCash
    private var receiveCurrencyDisplayed:CryptoCurrency = CryptoCurrency.bitcoinCash
    
    init(store: Store<ApplicationState>, exchangeFlow: ExchangeFlow?) {
        cryptos = CryptoCurrency.all
//        exchangeActionCreators = ExchangeActionCreators.shared
        depositCrypto = BehaviorRelay<CryptoCurrency>(value: .monero)
        receiveCrypto = BehaviorRelay<CryptoCurrency>(value: .bitcoin)
        didSetCurrentAddressForDeposit = false
        didSetCurrentAddressForReceive = false
        disposeBag = DisposeBag()
        receiveAmountString = BehaviorRelay<String>(value: "")
        depositAmountString = BehaviorRelay<String>(value: "")
        receiveAddress = BehaviorRelay<String>(value: "")
        depositRefundAddress = BehaviorRelay<String>(value: "")
        depositMinAmount = BehaviorRelay<String>(value: "0.0")
        depositMaxAmount = BehaviorRelay<String>(value: "0.0")
        receiveMinAmount = BehaviorRelay<String>(value: "0.0")
        receiveMaxAmount = BehaviorRelay<String>(value: "0.0")

        self.exchangeFlow = exchangeFlow
        self.store = store
        super.init()
        NotificationCenter.default.addObserver(forName: Notification.Name("langChanged"), object: nil, queue: nil) { [weak self] notification in
            guard let self = self else {
                return
            }
            
            let clearButton = UIBarButtonItem(
                title: NSLocalizedString("clear", comment: ""),
                style: .plain,
                target: self,
                action: #selector(self.clear))
            
            let tradesHistoryButton = UIBarButtonItem(
                title: NSLocalizedString("history", comment: ""),
                style: .plain,
                target: self,
                action: #selector(self.navigateToTradeHistory))
            
            self.navigationItem.rightBarButtonItem = clearButton
            self.navigationItem.leftBarButtonItem = tradesHistoryButton

        }
        tabBarItem = UITabBarItem(
            title: title,
            image: UIImage(named: "exchange_icon")?.withRenderingMode(.alwaysTemplate),
            selectedImage: UIImage(named: "exchange_icon")?.withRenderingMode(.alwaysTemplate)
        )
    }
        
    @objc
    func onDepositPickerButtonTap() {
        providesPresentationContextTransitionStyle = true
        definesPresentationContext = true
        
        let currencyPickerVC = CurrencyPickerViewController(selectedItem: depositCrypto.value)
        currencyPickerVC.type = .deposit
        currencyPickerVC.delegate = self
        currencyPickerVC.modalPresentationStyle = .overCurrentContext
        tabBarController?.present(currencyPickerVC, animated: true)
    }
    
    @objc
    func onReceivePickerButtonTap() {
        providesPresentationContextTransitionStyle = true
        definesPresentationContext = true
        
        let currencyPickerVC = CurrencyPickerViewController(selectedItem: receiveCrypto.value)
        currencyPickerVC.type = .receive
        currencyPickerVC.delegate = self
        currencyPickerVC.modalPresentationStyle = .overCurrentContext
        tabBarController?.present(currencyPickerVC, animated: true)
    }
    
    private func showExchangeSelection() {
        providesPresentationContextTransitionStyle = true
        definesPresentationContext = true
        let currentPair = Pair(from: depositCrypto.value, to: receiveCrypto.value, reverse: false)
        let providers = exchangeList.exchangeProviders(for: currentPair)
        let selectedProvider = exchange.provider
        let pickerVC = PickerViewController(items: providers, selectedItem: selectedProvider)
        pickerVC.pickerTitle = "Switch exchange"
        pickerVC.onPick = { provider in
            guard let exchange = self.exchangeList.exchange(for: provider) else {
                return
            }
            
            self.exchange = exchange
        }
        pickerVC.modalPresentationStyle = .overCurrentContext
        tabBarController?.present(pickerVC, animated: true)
    }
    
    override func configureBinds() {
        let receiveAmountObserver = receiveAmountString.asObservable()
        let depositAmountObserver = depositAmountString.asObservable()
        let receiveLimitsObserver = receiveLimits.asObservable()
        let depositLimitsObserver = depositLimits.asObservable()
        
        let depositOnTapGesture = UITapGestureRecognizer(target: self, action: #selector(onDepositPickerButtonTap))
        contentView.depositCardView.pickerButtonView.addGestureRecognizer(depositOnTapGesture)
        
        let backButton = UIBarButtonItem(title: "", style: .plain, target: self, action: nil)
        navigationItem.backBarButtonItem = backButton
        
        let receiveOnTapGesture = UITapGestureRecognizer(target: self, action: #selector(onReceivePickerButtonTap))
        contentView.receiveCardView.pickerButtonView.addGestureRecognizer(receiveOnTapGesture)
        contentView.depositCardView.addressContainer.presenter = self
        contentView.depositCardView.addressContainer.updateResponsible = self
        contentView.receiveCardView.addressContainer.presenter = self
        contentView.receiveCardView.addressContainer.updateResponsible = self
        contentView.receiveCardView.amountTextField.isUserInteractionEnabled = false
        exchangeNameView.title = NSLocalizedString("exchange", comment: "")
        exchangeNameView.titleLabel.textColor = UserInterfaceTheme.current.text
        exchangeNameView.subtitle = exchange.provider.formatted()
        exchangeNameView.subtitleLabel.textColor = UserInterfaceTheme.current.textVariants.highlight
        exchangeNameView.onTap = { [weak self] in
            self?.showExchangeSelection()
        }
        navigationItem.titleView = exchangeNameView
        contentView.receiveCardView.amountTextField.textColor = UserInterfaceTheme.current.text
        contentView.depositCardView.amountTextField.textColor = UserInterfaceTheme.current.text
        (contentView.receiveCardView.addressContainer.textView.originText <-> receiveAddress)
            .disposed(by: disposeBag)

        (contentView.depositCardView.addressContainer.textView.originText <-> depositRefundAddress)
            .disposed(by: disposeBag)
        
        (contentView.depositCardView.amountTextField.rx.text.orEmpty <-> depositAmountString)
            .disposed(by: disposeBag)
        
        (contentView.receiveCardView.amountTextField.rx.text.orEmpty <-> receiveAmountString)
            .disposed(by: disposeBag)
        
        let depositCryptoObserver = depositCrypto.asObservable()
        
        depositCryptoObserver
            .bind { self.onDepositCryptoChange($0) }
            .disposed(by: disposeBag)
        
        let receiveCryptoObserver = receiveCrypto.asObservable()
        
        Observable.combineLatest(depositCryptoObserver, receiveCryptoObserver)
            .subscribe(onNext: { [weak self] deposit, receive in self?.changeExchange(deposit: deposit, receive: receive) })
            .disposed(by: disposeBag)
        
        depositAmountObserver
            .filter { !$0.isEmpty }
            .map { Double($0.replacingOccurrences(of: ",", with: ".")) ?? 0 }
            .map { self.exchange.calculateAmount($0, from: self.depositCrypto.value, to: self.receiveCrypto.value) }
            .flatMap { $0 }
            .map { return $0.formatted() }
            .bind(to: contentView.receiveCardView.amountTextField.rx.text)
            .disposed(by: disposeBag)
        
        depositAmountObserver
            .filter { $0.isEmpty }
            .map { _ in return nil }
            .bind(to: contentView.receiveCardView.amountTextField.rx.text)
            .disposed(by: disposeBag)
        
        receiveAmountObserver
            .filter { !$0.isEmpty }
            .map { Double($0.replacingOccurrences(of: ",", with: ".")) ?? 0 }
            .map { self.exchange.calculateAmount($0, from: self.receiveCrypto.value, to: self.depositCrypto.value) }
            .flatMap { $0 }
            .map { return $0.formatted() }
            .bind(to: contentView.depositCardView.amountTextField.rx.text)
            .disposed(by: disposeBag)
        
        receiveAmountObserver
            .filter { $0.isEmpty }
            .map { _ in return nil }
            .bind(to: contentView.depositCardView.amountTextField.rx.text)
            .disposed(by: disposeBag)
        
        receiveCryptoObserver.bind {
            self.onReceiveCryptoChange($0)
            }
            .disposed(by: disposeBag)
        
        Observable.combineLatest(receiveLimitsObserver.map({ $0.max }), receiveCryptoObserver) { limit, currency -> String? in
                guard
                    limit?.value != 0,
                    let limitFormatted = limit?.formatted() else {
                    return nil
                }
            
                return String(format: "%@: %@ %@", NSLocalizedString("max", comment: ""), limitFormatted, currency.formatted())
            }
            .bind(to: contentView.receiveCardView.maxLabel.rx.text)
            .disposed(by: disposeBag)
        
        Observable.combineLatest(receiveLimitsObserver.map({ $0.min }), receiveCryptoObserver) { limit, currency -> String? in
            guard
                limit?.value != 0,
                let limitFormatted = limit?.formatted() else {
                return nil
            }
            
            return String(format: "%@: %@ %@", NSLocalizedString("min", comment: ""), limitFormatted, currency.formatted())
            }
            .bind(to: contentView.receiveCardView.minLabel.rx.text)
            .disposed(by: disposeBag)
        
        Observable.combineLatest(depositLimitsObserver.map({ $0.max }), depositCryptoObserver) { limit, currency -> String? in
            guard
                limit?.value != 0,
                let limitFormatted = limit?.formatted() else {
                return nil
            }
            
            return String(format: "%@: %@ %@", NSLocalizedString("max", comment: ""), limitFormatted, currency.formatted())
            }
            .bind(to: contentView.depositCardView.maxLabel.rx.text)
            .disposed(by: disposeBag)
        
        Observable.combineLatest(depositLimitsObserver.map({ $0.min }), depositCryptoObserver) { limit, currency -> String? in
            guard
                limit?.value != 0,
                let limitFormatted = limit?.formatted() else {
                return nil
            }
            
            return String(format: "%@: %@ %@", NSLocalizedString("min", comment: ""), limitFormatted, currency.formatted())
            }
            .bind(to: contentView.depositCardView.minLabel.rx.text)
            .disposed(by: disposeBag)
        
        contentView.clearButton.addTarget(self, action: #selector(clear), for: .touchUpInside)
        contentView.exchangeButton.addTarget(self, action: #selector(exhcnage), for: .touchUpInside)
        
        onDepositCryptoChange(depositCrypto.value)
        onReceiveCryptoChange(receiveCrypto.value)
        didSetCurrentAddressForDeposit = false
        didSetCurrentAddressForReceive = false
        setProviderTitle()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let clearButton = UIBarButtonItem(
            title: NSLocalizedString("clear", comment: ""),
            style: .plain,
            target: self,
            action: #selector(clear))
        
        let tradesHistoryButton = UIBarButtonItem(
            title: NSLocalizedString("history", comment: ""),
            style: .plain,
            target: self,
            action: #selector(navigateToTradeHistory))
        
        navigationItem.rightBarButtonItem = clearButton
        navigationItem.leftBarButtonItem = tradesHistoryButton
        navigationItem.rightBarButtonItem?.tintColor = UserInterfaceTheme.current.text

        navigationItem.leftBarButtonItem?.tintColor =
            UserInterfaceTheme.current.text
                XMRTOExchange.asyncUpdateUri()
    }
    
    override func setBarStyle() {
        super.setBarStyle()
        exchangeNameView.backgroundColor = UserInterfaceTheme.current.background
        navigationItem.leftBarButtonItem?.tintColor = UserInterfaceTheme.current.text
        navigationItem.rightBarButtonItem?.tintColor = UserInterfaceTheme.current.text
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        store.subscribe(self, onlyOnChange: [
            \ApplicationState.exchangeState,
            \ApplicationState.walletState
        ])
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        highlightNeededFields()
        
        if (depositCrypto.value == CryptoCurrency.monero) {
            contentView.depositCardView.addressContainer.availablePickers = []
        } else {
            contentView.depositCardView.addressContainer.availablePickers = [.paste, .qrScan, .addressBook]
        }
        
        if (receiveCrypto.value == CryptoCurrency.monero) {
            contentView.receiveCardView.addressContainer.availablePickers = [.paste, .qrScan, .addressBook, .subaddress]
        } else {
            contentView.receiveCardView.addressContainer.availablePickers = [.paste, .qrScan, .addressBook]
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        store.unsubscribe(self)
    }
    
    override func setTitle() {
        title = NSLocalizedString("exchange", comment: "")
    }
    
    // MARK: StoreSubscriber
    
    func onStateChange(_ state: ApplicationState) {
        changedWallet(state.walletState)
    }
    
    // MARK: CurrencyPickerDelegate
    
    func onPicked(item: CryptoCurrency, pickerType: ExchangeCardType) {
        switch pickerType {
        case .deposit:
            depositCrypto.accept(item)
            if (item == CryptoCurrency.monero) {
                contentView.depositCardView.addressContainer.availablePickers = []
            } else {
                contentView.depositCardView.addressContainer.availablePickers = [.paste, .qrScan, .addressBook]
            }

        case .receive:
            receiveCrypto.accept(item)
            if (item == CryptoCurrency.monero) {
                contentView.receiveCardView.addressContainer.availablePickers = [.paste, .qrScan, .addressBook, .subaddress]
            } else {
                contentView.receiveCardView.addressContainer.availablePickers = [.paste, .qrScan, .addressBook]
            }
        case .unknown:
            return
        }
    }
    
    private func exchangeChanged() {
        updateLimits()
        setProviderTitle()
        exchangeNameView.subtitle = exchange.provider.formatted()
//        contentView.depositCardView.amountTextField.isUserInteractionEnabled = false
        contentView.depositCardView.wantsEstimatedField = false
        contentView.receiveCardView.wantsEstimatedField = true
        highlightNeededFields()
    }
    
    private func highlightNeededFields() {
        contentView.depositCardView.amountTextField.bottomBorder.backgroundColor = UserInterfaceTheme.current.purple.highlight.cgColor
        contentView.receiveCardView.amountTextField.bottomBorder.backgroundColor = UserInterfaceTheme.current.gray.dim.cgColor
    }
    
    private func changeExchange(deposit: CryptoCurrency, receive: CryptoCurrency) {
        let isReverse = deposit == .monero && receive == .bitcoin ? false : true
        
        if let exchange = exchangeList.exchange(for: Pair(from: deposit, to: receive, reverse: isReverse)) {
            self.exchange = exchange
        }
    }
    
    private func onDepositCryptoChange(_ crypto: CryptoCurrency) {
        contentView.depositCardView.pickerButtonView.pickedCurrency.text = crypto.formatted()
        
        if store.state.walletState.walletType.currency == crypto {
            contentView.depositCardView.pickerButtonView.walletNameLabel.text = store.state.walletState.name
            if depositCurrencyDisplayed != crypto {
                depositCurrencyDisplayed = crypto
                depositRefundAddress.accept(store.state.walletState.address)
            }
        } else {
            contentView.depositCardView.pickerButtonView.walletNameLabel.text = nil
            contentView.depositCardView.addressContainer.textView.text = nil
            if (depositCurrencyDisplayed != crypto) {
                depositCurrencyDisplayed = crypto
                depositRefundAddress.accept("")
            }
        }
    
        
        let amount = Double(receiveAmountString.value) ?? 0
        exchange.calculateAmount(amount, from: crypto, to: receiveCrypto.value)
            .map { $0.formatted() }
            .bind(to: receiveAmountString)
            .disposed(by: disposeBag)
        
        contentView.depositCardView.addressContainer.isUserInteractionEnabled = store.state.walletState.walletType.currency != crypto
        setProviderTitle()
        updateLimits()
    }
    
    private func updateLimits() {
        exchange.fetchLimist(from: depositCrypto.value, to: receiveCrypto.value)
            .catchErrorJustReturn((min: nil, max: nil))
            .bind(to: depositLimits)
            .disposed(by: disposeBag)
        depositLimits.accept((min: nil, max: nil))
    }
    
    private func onReceiveCryptoChange(_ crypto: CryptoCurrency) {
        contentView.receiveCardView.pickerButtonView.pickedCurrency.text = crypto.formatted()
        
        if store.state.walletState.walletType.currency == crypto {
            contentView.receiveCardView.pickerButtonView.walletNameLabel.text = store.state.walletState.name
            if (receiveCurrencyDisplayed != crypto) {
                receiveAddress.accept(store.state.walletState.address)
                receiveCurrencyDisplayed = crypto
            }
        } else {
            if (receiveCurrencyDisplayed != crypto) {
                receiveAddress.accept("")
                receiveCurrencyDisplayed = crypto
            }
            contentView.receiveCardView.pickerButtonView.walletNameLabel.text = nil
            contentView.receiveCardView.addressContainer.textView.text = nil
        }
        
        setProviderTitle()
        updateLimits()
    }
    
    private func changedWallet(_ walletState: WalletState) {
        if depositCrypto.value == walletState.walletType.currency {
            if contentView.depositCardView.pickerButtonView.walletNameLabel.text != walletState.name {
                contentView.depositCardView.pickerButtonView.walletNameLabel.text = walletState.name
                depositRefundAddress.accept(store.state.walletState.address)
            }
        }
        
        if receiveCrypto.value == walletState.walletType.currency {
            if contentView.receiveCardView.pickerButtonView.walletNameLabel.text != walletState.name {
                contentView.receiveCardView.pickerButtonView.walletNameLabel.text = walletState.name
                receiveAddress.accept("")
            }
        }
        
        contentView.setNeedsLayout()
    }
    
    private func calculateAmount(forInput input: CryptoCurrency, output: CryptoCurrency, amount: String, rates: ExchangeRate) -> String {
        let rate = input == output
            ? 1
            : rates[input]?[output] ?? 0
        let formattedAmount = amount.replacingOccurrences(of: ",", with: ".")
        let result = rate * (Double(formattedAmount) ?? 0)
        let outputAmount: Amount
        
        switch receiveCrypto.value {
        case .bitcoin:
            outputAmount = BitcoinAmount(from: String(result))
        case .monero:
            outputAmount = MoneroAmount(from: String(result))
        case .ethereum:
            outputAmount = EthereumAmount(from: String(result))
        default:
            outputAmount = EDAmount(from: String(result), currency: receiveCrypto.value)
        }
        
        return outputAmount.formatted()
    }
    
    private func updateReceiveResult(with amount: Amount) {
        if
            let crypto = amount.currency as? CryptoCurrency,
            crypto == receiveCrypto.value {
            contentView.receiveCardView.receiveViewAmount.text = String(format: "%@ %@", amount.formatted(), receiveCrypto.value.formatted())
            return
        }
        
        let rate = depositCrypto.value == receiveCrypto.value
            ? 1
            :self.store.state.exchangeState.rates[depositCrypto.value]?[receiveCrypto.value] ?? 0
        let formattedAmount = amount.formatted().replacingOccurrences(of: ",", with: ".")
        let result = rate * (Double(formattedAmount) ?? 0)
        let outputAmount: Amount
        
        switch receiveCrypto.value {
        case .bitcoin:
            outputAmount = BitcoinAmount(from: String(result))
        case .monero:
            outputAmount = MoneroAmount(from: String(result))
        case .ethereum:
            outputAmount = EthereumAmount(from: String(result))
        default:
            outputAmount = EDAmount(from: String(result), currency: receiveCrypto.value)
        }
        
        let formattedOutputAmount = amountForDisplayFormatted(from: outputAmount.formatted())
        contentView.receiveCardView.receiveViewAmount.text = String(format: "%@ %@", formattedOutputAmount, receiveCrypto.value.formatted())
    }
    
    private func setProviderTitle() {
        var title: String
        var icon: String

        switch exchange.provider {
        case .changenow:
            title = "Powered by Changenow.io"
            icon = "cn_logo"
        case .morph:
            title = "Powered by Morphtoken"
            icon = "morphtoken_logo"
        case .xmrto:
            title = "Powered by XMR.to"
            icon = "xmr_to_logo"
        }
        
        guard contentView.exchangeDescriptionLabel.text != title else {
            return
        }
        
        contentView.dispclaimerLabel.text = NSLocalizedString("amount_is_estimate", comment: "")
        changeProviderTitle(title, icon: UIImage(named: icon))
    }
    
    private func changeProviderTitle(_ title: String, icon: UIImage? = nil) {
        contentView.exchangeDescriptionLabel.text =  title
        contentView.exchangeLogoImage.image = icon
        contentView.exchangeDescriptionLabel.flex.markDirty()
        contentView.descriptionView.flex.layout()
    }
    
    @objc
    private func clear() {
        depositAmountString.accept("")
        receiveAmountString.accept("")
        updateReceiveResult(with: makeAmount(0 as UInt64, currency: receiveCrypto.value))
        store.dispatch(ExchangeState.Action.changedTrade(nil))
    }
    
    @objc
    func navigateToTradeHistory() {
        exchangeFlow?.change(route: .tradesHistory)
    }
    
    @objc
    private func exhcnage() {
        let refundAddress = depositRefundAddress.value
        
        let outputAddress = receiveAddress.value
        
        guard !refundAddress.isEmpty else {
            showOKInfoAlert(message: NSLocalizedString("refund_address_is_empty", comment: ""))
            return
        }
        
        guard !outputAddress.isEmpty else {
            showOKInfoAlert(message: NSLocalizedString("receive_address_is_empty", comment: ""))
            return
        }
        
        let amountString = depositAmountString.value.replacingOccurrences(of: ",", with: ".")
        let amount = makeAmount(amountString, currency: depositCrypto.value)
        let amountDouble = Double(amountString) ?? 0
        let request: TradeRequest
        let limits = depositLimits.value
        
        if
            let min = limits.min,
            let minAmount = Double(min.formatted()),
            minAmount > amountDouble {
            showErrorAlert(error: ExchangerError.amountIsLessMinLimit)
            return
        }
        
        if
            let max = limits.max,
            let maxAmount = Double(max.formatted()),
            maxAmount < amountDouble {
            showErrorAlert(error: ExchangerError.amountIsOverMaxLimit)
            return
        }
        
        
        switch exchange.provider {
        case .changenow:
            request = ChangeNowTradeRequest(
                from: depositCrypto.value,
                to: receiveCrypto.value,
                address: receiveAddress.value,
                amount: amountString,
                refundAddress: depositRefundAddress.value)
        case .morph:
            request = MorphTradeRequest(from: depositCrypto.value, to: receiveCrypto.value, refundAddress: depositRefundAddress.value, outputAdress: receiveAddress.value, amount: amount)
        case .xmrto:
            request = XMRTOTradeRequest(amount: amount, address: receiveAddress.value)
        }
        
        showSpinnerAlert(withTitle: NSLocalizedString("create_exchange", comment: "")) { alert in
            self.exchange.createTrade(from: request)
                .subscribe(onNext: { trade in
                    alert.dismiss(animated: true) {
                        self.onTradeCreated(trade, amount: amount)
                    }
                }, onError: { error in
                    alert.dismiss(animated: true) {
                        self.showErrorAlert(error: error)
                    }
                }).disposed(by: self.disposeBag)
        }
    }
    
    private func onTradeCreated(_ trade: Trade, amount: Amount) {
        TradesList.shared.add(
            tradeID: trade.id,
            date: Date(),
            provider: exchange.provider,
            from: depositCrypto.value,
            to: receiveCrypto.value)
        
        let alert = ExchangeAlertViewController()
        alert.onDone = { [weak self] in
            self?.exchangeFlow?.change(route: .exchangeResult(trade, amount))
        }
        
        alert.setTradeID(trade.id)
        present(alert, animated: true)
    }
}

extension ExchangeViewController: QRUriUpdateResponsible {
    func getCrypto(for addressView: AddressView) -> CryptoCurrency {
        return addressView.tag == 2000 ? depositCrypto.value : receiveCrypto.value
    }
    
    func updated(_ addressView: AddressView, withURI uri: QRUri) {
        guard let amount = uri.amount?.formatted() else {
            return
        }
        
        let amountReply = addressView.tag == 2000 ? depositAmountString : receiveAmountString
        amountReply.accept(amount)
    }
}


class ExchangeContentAlertView: BaseFlexView {
    let messageLabel: UILabel
    let copiedLabel: UILabel
    let copyButton: CopyButton
    
    required init() {
        messageLabel = UILabel()
        copiedLabel = UILabel(fontSize: 12)
        copyButton = CopyButton(title: NSLocalizedString("copy_id", comment: ""), fontSize: 14)
        super.init()
    }
    
    override func configureView() {
        super.configureView()
        messageLabel.textAlignment = .center
        messageLabel.numberOfLines = 0
        messageLabel.font = applyFont(ofSize: 16)
        messageLabel.textColor = UserInterfaceTheme.current.text
        copiedLabel.textAlignment = .center
        copiedLabel.textColor = UserInterfaceTheme.current.text
        copyButton.backgroundColor = UserInterfaceTheme.current.blue.dim
        copyButton.layer.borderColor = UserInterfaceTheme.current.blue.main.cgColor
        backgroundColor = .clear
    }
    
    override func configureConstraints() {
        rootFlexContainer.flex.alignItems(.center).backgroundColor(.clear).define { flex in
            flex.addItem(messageLabel).margin(UIEdgeInsets(top: 0, left: 30, bottom: 30, right: 30))
            flex.addItem(copiedLabel).height(10).marginBottom(5)
            flex.addItem(copyButton).height(56).marginBottom(20).width(80%)
        }
    }
    
    func setTradeID(_ id: String) {
        copyButton.textHandler = { [weak self] in
            self?.copied()
            return id
        }
        
        messageLabel.text = String(format: NSLocalizedString("please_save_sec_key", comment: ""), id)
        messageLabel.flex.markDirty()
        flex.layout()
    }
    
    private func copied() {
        copiedLabel.text = NSLocalizedString("copied", comment: "")
        copiedLabel.flex.markDirty()
        flex.layout()
    }
}

class ExchangeTransactions {
    static let shared: ExchangeTransactions = ExchangeTransactions()
    
    private static let name = "exchange_transactions.txt"
    private static var url: URL {
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent(name)
    }
    
    private static func load() -> JSON {
        if !FileManager.default.fileExists(atPath: url.path) {
            FileManager.default.createFile(atPath: url.path, contents: nil, attributes: nil)
        }
        
        guard
            let data = try? Data(contentsOf: url),
            let json = try? JSON(data: data) else {
                return JSON()
        }
        
        return json
    }
    
    private var json: JSON
    
    init() {
        json = ExchangeTransactions.load()
    }
    
    func getAll() -> [JSON]? {
        return json.array
    }
    
    func getExchangeProvider(by transactionID: String) -> String? {
        return json.array?.filter({ j -> Bool in
            return j["txID"].stringValue == transactionID
        }).first?["provider"].string
    }
    
    func getTradeID(by transactionID: String) -> String? {
        return json.array?.filter({ j -> Bool in
            return j["txID"].stringValue == transactionID
        }).first?["tradeID"].string
    }
    
    func getTradeByTransactionID(by transactionID: String) -> JSON? {
        return json.array?.filter({ j -> Bool in
            return j["txID"].stringValue == transactionID
        }).first
    }
    
    func add(tradeID: String, transactionID: String, provider: String) throws {
        guard getTradeID(by: transactionID) == nil else {
            return
        }
        
        let item = JSON([
            "tradeID": tradeID,
            "txID": transactionID,
            "provider": provider,
            "date": Date().timeIntervalSince1970
        ])
        
        let array = json.arrayValue + [item]
        json = JSON(array)
        try save()
    }
    
    private func save() throws {
        try json.rawData().write(to: ExchangeTransactions.url)
    }
}
