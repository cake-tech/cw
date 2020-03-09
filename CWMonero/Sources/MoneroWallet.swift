import Foundation
import CakeWalletLib
import Alamofire

// fixme: remove and rework this shit

private let moneroBlockSize = 1000
public let walletQueue = DispatchQueue(label: "app.cakewallet.monero-wallet-queue", qos: .default)

public final class CachedValue<Val> {
    public var handler: (() -> Val)?
    public var filter: ((Val) -> Bool)?
    private var origin: Val
    private var lastUpdateDate: Date
    private let timeout: TimeInterval
    
    public init(origin: Val, timeout: TimeInterval, handler: (() -> Val)? = nil) {
        self.origin = origin
        self.timeout = timeout
        self.handler = handler
        self.lastUpdateDate = Date(timeIntervalSince1970: 0)
    }
    
    public func value() -> Val {
        
        if
            let filter = filter,
            filter(origin),
            let newVal = handler?() {
            origin = newVal
            lastUpdateDate = Date()
            return origin
        }
        
        let diff = Date().timeIntervalSince(lastUpdateDate)
        
        if
            diff > timeout,
            let newVal = handler?() {
            origin = newVal
            lastUpdateDate = Date()
        }
        
        return origin
    }
    
    public func isInvalided() -> Bool {
        let diff = Date().timeIntervalSince(lastUpdateDate)
        let isInvalided = diff > timeout
        return isInvalided
    }
}

private let cachedBlockchainTimeout: TimeInterval = 30
private var cachedBlockchainHeight = CachedValue(origin: UInt64(0), timeout: cachedBlockchainTimeout)

public final class MoneroWallet: Wallet {
    public static let walletType = WalletType.monero
    
    public var name: String {
        return moneroAdapter.name()
    }
    
    public var balance: Amount {
        return MoneroAmount(value: moneroAdapter.balance(for: accountIndex))
    }
    
    public var unlockedBalance: Amount {
        return MoneroAmount(value: moneroAdapter.unlockedBalance(for: accountIndex))
    }
    
    public var address: String {
        return moneroAdapter.address(for: accountIndex, addressIndex: addressIndex)
    }
    
    public var seed: String {
        return moneroAdapter.seed()
    }
    
    public var isConnected: Bool {
        return moneroAdapter.connectionStatus() != 0
    }
    
    public var keys: WalletKeys {
        return _keys
    }
    
    public var isWatchOnly: Bool {
        return _keys.spendKey.sec.range(of: "^0*$", options: .regularExpression, range: nil, locale: nil) != nil
    }
    
    public var currentHeight: UInt64 {
        let height = moneroAdapter.currentHeight()
        
        if config.isRecovery && (height == 1 || height == 0) {
            return restoreHeight
        } else {
            return height
        }
    }
    
    public var onNewBlock: ((UInt64) -> Void)?
    public var onBalanceChange: ((Wallet) -> Void)?
    public var onConnectionStatusChange: ((ConnectionStatus) -> Void)?
    public var onAddressChange: ((String) -> Void)?
    public private(set) var config: WalletConfig
    public private(set) var accountIndex: UInt32
    public private(set) var addressIndex: UInt32
    private var isBlocking: Bool
    
    private var moneroTransactionHistory: MoneroTransactionHistory?
    private lazy var _subaddresses: Subaddresses = {
        return Subaddresses(wallet: moneroAdapter)!
    }()
    private lazy var _accounts: Accounts = {
        return Accounts(wallet: moneroAdapter)!
    }()
    private lazy var secretSpendKey = moneroAdapter.secretSpendKey() ?? ""
    private lazy var publicSpendKey = moneroAdapter.publicSpendKey() ?? ""
    private lazy var publicViewKey = moneroAdapter.publicViewKey() ?? ""
    private lazy var secretViewKey = moneroAdapter.secretViewKey() ?? ""
    
    private var _keys: MoneroWalletKeys {
        return MoneroWalletKeys(
            spendKey: MoneroWalletKeysPair(pub: publicSpendKey, sec: secretSpendKey),
            viewKey: MoneroWalletKeysPair(pub: publicViewKey, sec: secretViewKey))
    }
    
    private var moneroAdapter: MoneroWalletAdapter
    private var restoreHeight: UInt64
    private var isAccountRefreshing: Bool
    private var isSaving: Bool
    
    public convenience init(moneroAdapter: MoneroWalletAdapter, config: WalletConfig, restoreHeight: UInt64, addressIndex: UInt32 = 0, accountIndex: UInt32 = 0) {
        self.init(moneroAdapter: moneroAdapter, config: config, addressIndex: addressIndex, accountIndex: accountIndex)
        self.restoreHeight = restoreHeight
//        self.moneroAdapter.setRefreshFromBlockHeight(restoreHeight)
    }
    
    public init(moneroAdapter: MoneroWalletAdapter, config: WalletConfig, addressIndex: UInt32 = 0, accountIndex: UInt32 = 0) {
        self.moneroAdapter = moneroAdapter
        self.isBlocking = false
        self.addressIndex = addressIndex
        self.accountIndex = accountIndex
        self.config = config
        restoreHeight = 0
        isAccountRefreshing = false
        isSaving = false
        self.moneroAdapter.delegate = self
        moneroTransactionHistory = nil
        
        if config.isRecovery {
            moneroAdapter.setIsRecovery(config.isRecovery)
        }
    }
    
    deinit {
        print("MoneroWallet deinit")
    }
    
    public func blockchainHeight() throws -> UInt64 {
        cachedBlockchainHeight.filter = { val in
            return val == 0
        }
        
        cachedBlockchainHeight.handler = { [weak self] in
            return self?.moneroAdapter.daemonBlockChainHeight() ?? 0
        }
        
        return cachedBlockchainHeight.value()
    }
    
    public func changePassword(newPassword: String) throws {
        try moneroAdapter.setPassword(newPassword)
    }
    
    public func save() throws {
        guard !isBlocking || !isSaving else {
            return
        }

        isSaving = true
        try walletQueue.sync { [weak self] in
            print("saving: \(Date())")
            try self?.moneroAdapter.save()
            self?.isSaving = false
        }
    }
    
    public func rawsave() throws {
        guard !isBlocking || !isSaving else {
            return
        }
        
        isSaving = true
        try moneroAdapter.save()
        isSaving = false
    }
    
    public func connect(toNode node: NodeDescription) throws {
        guard !isBlocking else {
            return
        }
        
        moneroAdapter.setDaemonAddress(node.uri, login: node.login, password: node.password)
        try moneroAdapter.connectToDaemon()
    }
    
    public func close() {
        isBlocking = true
        moneroAdapter.delegate = nil
        
        walletQueue.async {
            self.moneroAdapter.close()
            self.moneroAdapter.clear()
            self.isBlocking = false
        }
    }
    
    public func startUpdate() {
        guard !isBlocking else {
            return
        }
        
        moneroAdapter.startRefreshAsync()
    }  
    
    public func transactions() -> TransactionHistory {
        if let moneroTransactionHistory = self.moneroTransactionHistory {
            return moneroTransactionHistory
        } else {
            let _moneroTransactionHistory = MoneroTransactionHistory(moneroWalletHistoryAdapter: MoneroWalletHistoryAdapter(wallet: moneroAdapter))
            self.moneroTransactionHistory = _moneroTransactionHistory
            return _moneroTransactionHistory
        }
    }
    
    public func subaddresses() -> Subaddresses {
        _subaddresses.refresh(accountIndex)
        return _subaddresses
    }
    
    public func accounts() -> Accounts {
        if !isAccountRefreshing {
            isAccountRefreshing = true
            _accounts.refresh()
        }
        
        isAccountRefreshing = false
        return _accounts
    }
    
    public func send(amount: Amount?, to address: String, withPriority priority: TransactionPriority) throws -> PendingTransaction {
        do {
            let moneroPendingTransactionAdapter = try self.moneroAdapter.createTransaction(
                toAddress: address,
                withPaymentId: "",
                amountStr: amount?.formatted(),
                priority: priority.rawValue,
                accountIndex: accountIndex)
            return MoneroPendingTransaction(moneroPendingTransactionAdapter: moneroPendingTransactionAdapter)
        } catch let error as NSError {
            if let transactionError = TransactionError(from: error, amount: amount, balance: self.balance) {
                throw transactionError
            } else {
                throw error
            }
        }
    }
    
    public func send(amount: Amount?, to address: String, paymentID: String = "", withPriority priority: TransactionPriority) throws -> PendingTransaction {
        do {
            let moneroPendingTransactionAdapter = try self.moneroAdapter.createTransaction(
                toAddress: address,
                withPaymentId: paymentID,
                amountStr: amount?.formatted(),
                priority: priority.rawValue,
                accountIndex: accountIndex)
            return MoneroPendingTransaction(moneroPendingTransactionAdapter: moneroPendingTransactionAdapter)
        } catch let error as NSError {
            if let transactionError = TransactionError(from: error, amount: amount, balance: self.balance) {
                throw transactionError
            } else {
                throw error
            }
        }
    }
    
    public func integratedAddress(for paymentId: String) -> String {
        return self.moneroAdapter.integratedAddress(for: paymentId)
    }
    
    public func getTransactionKey(for transactionId: String) -> String {
        return moneroAdapter.getTxKey(for: transactionId)
    }
    
    public func rescan(from height: UInt64, node: NodeDescription) throws {
//        let isRecovery = true
//        MoneroWalletGateway().recoveryWallet(withName: name, andSeed: seed, password: "", restoreHeight: 0)
//        moneroAdapter.pauseRefresh()
//        try MoneroWalletGateway().removeCacheFile(for: name)
//        moneroAdapter.setIsRecovery(isRecovery)
//        moneroAdapter.setRefreshFromBlockHeight(height)
//        try config.update(isRecovery: isRecovery)
//        try moneroAdapter.save()
//        try connect(toNode: node)
//        startUpdate()
    }
    
    public func rescan(from height: UInt64, password: String) throws {
        try walletQueue.sync {
            isBlocking = true
            print("rescan start")
            let _name = self.moneroAdapter.name()!
            let _seed = self.moneroAdapter.seed()!
            let gateway = MoneroWalletGateway()
            self.moneroAdapter.delegate = nil
            self.moneroAdapter.close()
            self.moneroAdapter.clear()
            try gateway.remove(withName: _name)
            let _moneroAdapter = MoneroWalletAdapter()!
            try _moneroAdapter.recovery(at: gateway.makeURL(for: _name).path, mnemonic: _seed, andPassword: password, restoreHeight: height)
            self.moneroAdapter = _moneroAdapter
            self.moneroTransactionHistory = nil
            let walletConfig = WalletConfig(isRecovery: true, date: Date(), url: gateway.makeConfigURL(for: _name))
            try walletConfig.save()
            self.config = walletConfig
            print("rescan end")
            isBlocking = false
            self.moneroAdapter.delegate = self
        }
    }
    
    public func changeAddress(index: UInt32) {
        guard index != addressIndex else {
            return
        }
        
        addressIndex = index
//        onBalanceChange?(self)
        onAddressChange?(address)
    }
    
    public func changeAccount(index: UInt32) {
        guard index != accountIndex else {
            return
        }
        
        accountIndex = index
        onBalanceChange?(self)
        onAddressChange?(address)
    }
}

// MARK: MoneroWallet + MoneroWalletAdapterDelegate

extension MoneroWallet: MoneroWalletAdapterDelegate {
    public func newBlock(_ block: UInt64) {
        onNewBlock?(block)
    }

    public func updated() {
        print("updated")
    }

    public func refreshed() {
        do {
            let blockchainheight = try blockchainHeight()
            let isRecovery = config.isRecovery
            
            guard currentWallet.currentHeight != 0 && blockchainheight != 0 else {
                return
            }
            
            if (blockchainheight >= currentHeight && blockchainheight - currentHeight < moneroBlockSize) {
                if currentHeight == blockchainheight && isRecovery {
                    try currentWallet.config.update(isRecovery: false)
                    self.onConnectionStatusChange?(.synced)
                    return
                }
                
                if (!isRecovery && isConnected) { 
                    self.onConnectionStatusChange?(.synced)
                }
            }
            
            if isRecovery {
                try save()
            }
        } catch {
            print(error)
        }
    }

    public func moneyReceived(_ txId: String!, amount: UInt64) {
        onBalanceChange?(self)
    }

    public func moneySpent(_ txId: String!, amount: UInt64) {
        onBalanceChange?(self)
    }

    public func unconfirmedMoneyReceived(_ txId: String!, amount: UInt64) {
        onBalanceChange?(self)
    }
}
