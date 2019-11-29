import CakeWalletCore
import CakeWalletLib

public struct SettingsState: StateType {
    public static func == (lhs: SettingsState, rhs: SettingsState) -> Bool {
        return lhs.isAuthenticated == rhs.isAuthenticated
            && lhs.isAuthenticated == rhs.isAuthenticated
            && lhs.transactionPriority == rhs.transactionPriority
            && rhs.node != nil
                ? lhs.node?.compare(with: rhs.node!) ?? false
                : lhs.node == nil
            && lhs.isAutoSwitchNodeOn == rhs.isAutoSwitchNodeOn
            && lhs.fiatCurrency == rhs.fiatCurrency
    }
    
    public enum Action: AnyAction {
        case pinSet
        case isAuthenticated
        case changeTransactionPriority(TransactionPriority)
        case changeCurrentNode(NodeDescription)
        case changeAutoSwitchNode(Bool)
        case changedFiatCurrency(FiatCurrency)
        case changedBiometricAuthentication(Bool)
        case changedDisplayBalance(BalanceDisplay)
        case changedShouldSaveRecipientAddress(Bool)
    }
    
    public let isPinCodeInstalled: Bool
    public let isAuthenticated: Bool
    public let isBiometricAuthenticationAllowed: Bool
    public let transactionPriority: TransactionPriority
    public let node: NodeDescription?
    public let isAutoSwitchNodeOn: Bool
    public let fiatCurrency: FiatCurrency
    public let displayBalance:BalanceDisplay
    public let saveRecipientAddresses:Bool
    
    public init(isPinCodeInstalled: Bool, isAuthenticated: Bool, isBiometricAuthenticationAllowed: Bool, transactionPriority: TransactionPriority, node: NodeDescription?, isAutoSwitchNodeOn: Bool, fiatCurrency: FiatCurrency, displayBalance:BalanceDisplay, saveRecipientAddresses:Bool) {
        self.isPinCodeInstalled = isPinCodeInstalled
        self.isAuthenticated = isAuthenticated
        self.isBiometricAuthenticationAllowed = isBiometricAuthenticationAllowed
        self.transactionPriority = transactionPriority
        self.node = node
        self.isAutoSwitchNodeOn = isAutoSwitchNodeOn
        self.fiatCurrency = fiatCurrency
        self.displayBalance = displayBalance
        self.saveRecipientAddresses = saveRecipientAddresses
    }
    
    public func reduce(_ action: SettingsState.Action) -> SettingsState {
        switch action {
        case let .changedShouldSaveRecipientAddress(shouldSave):
            return SettingsState(isPinCodeInstalled: isPinCodeInstalled, isAuthenticated: isAuthenticated, isBiometricAuthenticationAllowed: isBiometricAuthenticationAllowed, transactionPriority: transactionPriority, node: node, isAutoSwitchNodeOn: isAutoSwitchNodeOn, fiatCurrency: fiatCurrency, displayBalance:displayBalance, saveRecipientAddresses: shouldSave)
        case let .changedDisplayBalance(displayConfig):
            return SettingsState(isPinCodeInstalled: isPinCodeInstalled, isAuthenticated: isAuthenticated, isBiometricAuthenticationAllowed: isBiometricAuthenticationAllowed, transactionPriority: transactionPriority, node: node, isAutoSwitchNodeOn: isAutoSwitchNodeOn, fiatCurrency: fiatCurrency, displayBalance:displayConfig, saveRecipientAddresses: saveRecipientAddresses)
        case let .changedBiometricAuthentication(isAllowed):
            return SettingsState(isPinCodeInstalled: isPinCodeInstalled, isAuthenticated: isAuthenticated, isBiometricAuthenticationAllowed: isAllowed, transactionPriority: transactionPriority, node: node, isAutoSwitchNodeOn: isAutoSwitchNodeOn, fiatCurrency: fiatCurrency, displayBalance:displayBalance, saveRecipientAddresses: saveRecipientAddresses)
        case let .changedFiatCurrency(fiatCurrency):
            return SettingsState(isPinCodeInstalled: isPinCodeInstalled, isAuthenticated: isAuthenticated, isBiometricAuthenticationAllowed: isBiometricAuthenticationAllowed, transactionPriority: transactionPriority, node: node, isAutoSwitchNodeOn: isAutoSwitchNodeOn, fiatCurrency: fiatCurrency, displayBalance:displayBalance, saveRecipientAddresses: saveRecipientAddresses)
        case let .changeAutoSwitchNode(isAutoSwitchNodeOn):
            return SettingsState(isPinCodeInstalled: isPinCodeInstalled, isAuthenticated: isAuthenticated, isBiometricAuthenticationAllowed: isBiometricAuthenticationAllowed, transactionPriority: transactionPriority, node: node, isAutoSwitchNodeOn: isAutoSwitchNodeOn, fiatCurrency: fiatCurrency, displayBalance:displayBalance, saveRecipientAddresses: saveRecipientAddresses)
        case let .changeCurrentNode(node):
            return SettingsState(isPinCodeInstalled: isPinCodeInstalled, isAuthenticated: isAuthenticated, isBiometricAuthenticationAllowed: isBiometricAuthenticationAllowed, transactionPriority: transactionPriority, node: node, isAutoSwitchNodeOn: isAutoSwitchNodeOn, fiatCurrency: fiatCurrency, displayBalance:displayBalance, saveRecipientAddresses: saveRecipientAddresses)
        case let .changeTransactionPriority(priority):
            return SettingsState(isPinCodeInstalled: isPinCodeInstalled, isAuthenticated: isAuthenticated, isBiometricAuthenticationAllowed: isBiometricAuthenticationAllowed, transactionPriority: priority, node: node, isAutoSwitchNodeOn: isAutoSwitchNodeOn, fiatCurrency: fiatCurrency, displayBalance:displayBalance, saveRecipientAddresses: saveRecipientAddresses)
        case .isAuthenticated:
            return SettingsState(isPinCodeInstalled: isPinCodeInstalled, isAuthenticated: true, isBiometricAuthenticationAllowed: isBiometricAuthenticationAllowed, transactionPriority: transactionPriority, node: node, isAutoSwitchNodeOn: isAutoSwitchNodeOn, fiatCurrency: fiatCurrency, displayBalance:displayBalance, saveRecipientAddresses: saveRecipientAddresses)
        case .pinSet:
            return SettingsState(isPinCodeInstalled: true, isAuthenticated: isAuthenticated, isBiometricAuthenticationAllowed: isBiometricAuthenticationAllowed, transactionPriority: transactionPriority, node: node, isAutoSwitchNodeOn: isAutoSwitchNodeOn, fiatCurrency: fiatCurrency, displayBalance:displayBalance, saveRecipientAddresses: saveRecipientAddresses)
        }
    }
}
