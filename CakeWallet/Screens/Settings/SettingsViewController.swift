import UIKit
import CakeWalletLib
import CakeWalletCore
import FlexLayout
import ZIPFoundation
import CryptoSwift
import CWMonero
import SwiftyJSON


final class TextViewUITableViewCell: FlexCell {
    let textView: UITextView
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        textView = UITextView()
        textView.textColor = UserInterfaceTheme.current.text
        textView.backgroundColor = UserInterfaceTheme.current.settingCellColor
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        configureView()
        configureConstraints()
    }
    
    override func configureView() {
        super.configureView()
        textView.isEditable = false
        textView.isScrollEnabled = false
        contentView.addSubview(textView)
        accessoryType = .none
    }
    
    override func configureConstraints() {
        contentView.flex.addItem(textView).marginLeft(15).width(100%).height(100%)
    }
    
    func configure(attributedText: NSAttributedString) {
        textView.attributedText = attributedText
        textView.flex.markDirty()
        contentView.flex.layout(mode: .adjustHeight)
    }
}

private protocol ActionableCellItem {
    var action: (() -> Void)? { get }
}

final class SettingsViewController: BaseViewController<SettingsView>, UITableViewDelegate, UITableViewDataSource, StoreSubscriber {
    typealias StoreListenerState = ApplicationState
    enum SettingsSections: Int {
        case nodes, wallets, personal, backup, manualBackup, support
    }
    
    struct SettingsTextViewCellItem: CellItem {
        let attributedString: NSAttributedString
        
        init(attributedString: NSAttributedString) {
            self.attributedString = attributedString
        }
        
        func setup(cell: TextViewUITableViewCell) {
            cell.configure(attributedText: attributedString)
            cell.selectionStyle = .gray
            let bgView = UIView()
            bgView.backgroundColor = UserInterfaceTheme.current.gray.dim
            cell.selectedBackgroundView = bgView

            cell.backgroundColor = UserInterfaceTheme.current.settingCellColor
        }
    }
    
    struct SettingsCellItem: CellItem, ActionableCellItem {
        let title: String
        let action: (() -> Void)?
        let image: UIImage?
        
        init(title: String, image: UIImage? = nil, action: (() -> Void)? = nil) {
            self.title = title
            self.image = image
            self.action = action
        }
        
        func setup(cell: UITableViewCell) {
            cell.textLabel?.text = title
            cell.textLabel?.textColor = UserInterfaceTheme.current.text
            cell.backgroundColor = UserInterfaceTheme.current.settingCellColor
            cell.imageView?.image = image
            cell.selectionStyle = .gray
            let bgView = UIView()
            bgView.backgroundColor = UserInterfaceTheme.current.gray.dim
            cell.selectedBackgroundView = bgView
            let rightArrowImage = UIImage(named: "arrow_right")
            cell.accessoryView = UIImageView(image:rightArrowImage?.resized(to: CGSize(width: 6, height: 10)).withRenderingMode(.alwaysTemplate))
            cell.accessoryView?.tintColor = UserInterfaceTheme.current.blue.highlight
        }
    }
    
    final class SettingsSwitchCellItem: CellItem {
        let title: String
        let image: UIImage?
        let action: ((Bool, SettingsSwitchCellItem) -> Void)?
        let switcher: SwitchView = SwitchView()
        
        init(title: String, image: UIImage? = nil, isOn: Bool, action: ((Bool, SettingsSwitchCellItem) -> Void)? = nil) {
            self.title = title
            self.image = image
            self.action = action
            self.switcher.isOn = isOn
            config()
        }
        
        func setup(cell: UITableViewCell) {
            cell.textLabel?.text = title
            cell.textLabel?.textColor = UserInterfaceTheme.current.text
            cell.imageView?.image = image
            cell.accessoryView = switcher
            cell.selectionStyle = .gray
            let bgView = UIView()
            bgView.backgroundColor = UserInterfaceTheme.current.gray.dim
            cell.selectedBackgroundView = bgView
            switcher.onChangeHandler = { isOn in
                self.action?(isOn, self)
            }
        }
        
        private func config() {
            switcher.frame = CGRect(origin: .zero, size: CGSize(width: 70, height: 35))
        }
    }
    
    struct SettingsPickerCellItem<PickerItem: Formatted>: CellItem {
        let title: String
        let image: UIImage?
        let pickerOptions: [PickerItem]
        let action: ((PickerItem) -> Void)?
        let onFinish: ((PickerItem) -> Void)?
        private var selectedIndex: Int
        
        init(title: String,
             image: UIImage? = nil,
             pickerOptions: [PickerItem],
             selectedAtIndex: Int,
             action: ((PickerItem) -> Void)? = nil,
             onFinish: ((PickerItem) -> Void)? = nil) {
            self.title = title
            self.image = image
            self.action = action
            self.pickerOptions = pickerOptions
            self.selectedIndex = selectedAtIndex
            self.onFinish = onFinish
        }
        
        func setup(cell: SettingsPickerUITableViewCell<PickerItem>) {
            cell.configure(title: title, pickerOptions: pickerOptions, selectedOption: selectedIndex, action: action)
            cell.textLabel?.textColor = UserInterfaceTheme.current.text
            cell.imageView?.image = image
            cell.onFinish = onFinish
        }
    }
    
    struct SettingsInformativeCellItem: CellItem, ActionableCellItem {
        let title: String
        let informativeText:String
        let image: UIImage?
        let action: (() -> Void)?
        var wantsBlue:Bool = false
        
        init(title: String, informativeText:String, image:UIImage?, action:(() -> Void)?) {
            self.title = title
            self.informativeText = informativeText
            self.image = image
            self.action = action
        }
        
        func setup(cell: SettingsInformativeUITableViewCell) {
            cell.configure(title:title, informativeText:informativeText)
            cell.backgroundColor = UserInterfaceTheme.current.settingCellColor
            cell.imageView?.image = image
            if (wantsBlue) {
                cell.informativeBlue = true
            } else {
                cell.informativeBlue = false
            }
        }
    }
    
    weak var settingsFlow: SettingsFlow?
    
    var transactionPriority: TransactionPriority {
        return store.state.settingsState.transactionPriority
    }
    
    var fiatCurrency: FiatCurrency {
        return store.state.settingsState.fiatCurrency
    }
    
    var balanceType: BalanceDisplay {
        return store.state.settingsState.displayBalance
    }
    
    private let store: Store<ApplicationState>
    private var sections: [SettingsSections: [CellAnyItem]]
    private let backupService: BackupServiceImpl
    private var masterPassword: String {
        return try! KeychainStorageImpl.standart.fetch(forKey: .masterPassword)
    }
    
    private var displayedNodeHash:Int = 0
    
    init(store: Store<ApplicationState>, settingsFlow: SettingsFlow?, backupService: BackupServiceImpl) {
        self.store = store
        self.settingsFlow = settingsFlow
        self.backupService = backupService
        sections = [.wallets: [], .personal: []]
        super.init()
        tabBarItem = UITabBarItem(
            title: title,
            image: UIImage(named: "settings_icon")?.withRenderingMode(.alwaysTemplate),
            selectedImage: UIImage(named: "settings_icon")?.withRenderingMode(.alwaysTemplate)
        )
        self.store.subscribe(self, onlyOnChange: [\ApplicationState.settingsState])
    }
    
    override func configureBinds() {
        contentView.table.register(items: [
            SettingsTextViewCellItem.self,
            SettingsCellItem.self,
            SettingsPickerCellItem<TransactionPriority>.self,
            SettingsPickerCellItem<FiatCurrency>.self,
            SettingsPickerCellItem<BalanceDisplay>.self,
            SettingsInformativeCellItem.self
            ])
        contentView.table.delegate = self
        contentView.table.dataSource = self
        let transactionPriorities = [
            TransactionPriority.slow,
            TransactionPriority.default,
            TransactionPriority.fast,
            TransactionPriority.fastest
        ]
        
        let backButton = UIBarButtonItem(title: "", style: .plain, target: self, action: nil)
        navigationItem.backBarButtonItem = backButton
        
        let currentNode = SettingsInformativeCellItem(title: NSLocalizedString("current_node", comment: ""), informativeText:(self.store.state.settingsState.node?.uri ?? ""), image:nil,
            action: { [weak self] in
                self?.settingsFlow?.change(route:.nodes)
        })
        
        let displayBalances = SettingsPickerCellItem<BalanceDisplay>(
            title: NSLocalizedString("balance_type_title", comment: ""),
            pickerOptions: BalanceDisplay.all,
            selectedAtIndex: BalanceDisplay.all.index(of:balanceType) ?? 0) { [weak store] newBalance in
                print("newBalance \(newBalance)")
                store?.dispatch(
                    SettingsActions.changeBalanceDisplayMode(to: newBalance)
                )
        }

        let fiatCurrencyCellItem = SettingsPickerCellItem<FiatCurrency>(
            title: NSLocalizedString("currency", comment: ""),
            pickerOptions: FiatCurrency.all,
            selectedAtIndex: FiatCurrency.all.index(of: fiatCurrency) ?? 0) { [weak store] currency in
                store?.dispatch(
                    SettingsActions.changeCurrentFiat(currency: currency)
                )
        }
        
        let feePriorityCellItem = SettingsPickerCellItem<TransactionPriority>(
            title: NSLocalizedString("fee_priority", comment: ""),
            pickerOptions: transactionPriorities,
            selectedAtIndex: transactionPriorities.index(of: transactionPriority) ?? 0) { [weak store] priority in
                store?.dispatch(
                    SettingsActions.changeTransactionPriority(priority)
                )
        }
        
        let changePinCellItem = SettingsCellItem(title: NSLocalizedString("change_pin", comment: ""), action: { [weak self] in
            self?.presentChangePin()
        })
        
        let changeLanguage = SettingsCellItem(title: NSLocalizedString("change_language", comment: ""), action: { [weak self] in //fixme
            self?.presentChangeLanguage()
        })
        
        let saveRecipientAddress = SettingsSwitchCellItem(
            title: NSLocalizedString("save_recipient_address", comment:""),
            isOn: store.state.settingsState.saveRecipientAddresses,
            action: { [weak store] shouldStore, item in
                guard shouldStore != store?.state.settingsState.saveRecipientAddresses else {
                    return
                }
                
                store?.dispatch(
                    SettingsActions.changeShouldSaveRecipientAddress(shouldStore)
                )
            }
        )
        
        let darkmodeCellItem = SettingsSwitchCellItem(
            title: NSLocalizedString("dark_mode_setting_title", comment: ""),
            isOn: UserInterfaceTheme.current == .dark,
            action: { isDarkMode, item in
                guard ((isDarkMode == true) ? UserInterfaceTheme.dark : UserInterfaceTheme.light) != UserInterfaceTheme.current else {
                    return
                }
                switch UserInterfaceTheme.current {
                case .dark:
                    UserInterfaceTheme.current = .light
                case .light:
                    UserInterfaceTheme.current = .dark
                }
                
        })

        let biometricCellItem = SettingsSwitchCellItem(
            title: NSLocalizedString("allow_biometric_authentication", comment: ""),
            isOn: store.state.settingsState.isBiometricAuthenticationAllowed,
            action: { [weak store] isAllowed, item in
                guard isAllowed != store?.state.settingsState.isBiometricAuthenticationAllowed else {
                    return
                }
                
                store?.dispatch(
                    SettingsActions.changeBiometricAuthentication(isAllowed: isAllowed, handler: { isAllowed in
                        DispatchQueue.main.async {
                            item.switcher.isOn = isAllowed
                        }
                    })
                )
        })
        //        let rememberPasswordCellItem = SettingsSwitchCellItem(
        //            title: NSLocalizedString("remember_pin", comment: ""),
        //            isOn: false // accountSettings.isPasswordRemembered
        //        ) { [weak self] isOn, item in
        //            //                self?.accountSettings.isPasswordRemembered = isOn
        //        }
        
        let termSettingsCellItem = SettingsCellItem(
            title: NSLocalizedString("terms", comment: ""),
            action: { [weak self] in
                self?.settingsFlow?.change(route: .terms)
        })
        let createBackupCellItem = SettingsCellItem(
            title: NSLocalizedString("save_backup_file", comment: ""),
            action: { [weak self] in
                self?.askToShowBackupPasswordAlert() {
                    self?.showSpinnerAlert(withTitle: NSLocalizedString("creating_backup", comment: "")) { [weak self] alert in
                        do {
                            guard
                                let password = self?.masterPassword,
                                let backupService = self?.backupService else {
                                    return
                            }
                            
                            let url = try backupService.exportToTmpFile(withPassword: password)
                            
                            alert.dismiss(animated: true) {
                                let activityViewController = UIActivityViewController(
                                    activityItems: [url],
                                    applicationActivities: nil)
                                activityViewController.excludedActivityTypes = [
                                    UIActivityType.message, UIActivityType.mail,
                                    UIActivityType.print, UIActivityType.airDrop]
                                self?.present(activityViewController, animated: true)
                            }
                        } catch {
                            alert.dismiss(animated: true) {
                                self?.onBackupSave(error: error)
                            }
                        }
                    }
                }
        })
        let backupNowCellItem = SettingsCellItem(
            title: NSLocalizedString("backup_now", comment: ""),
            action: { [weak self] in
                self?.askToShowBackupPasswordAlert() {
                    self?.showSpinnerAlert(withTitle: NSLocalizedString("creating_backup", comment: "")) { [weak self] alert in
                        autoBackup(force: true, handler: { error in
                            alert.dismiss(animated: true) {
                                guard let error = error else {
                                    self?.showOKInfoAlert(
                                        title: NSLocalizedString("backup_uploaded", comment: ""),
                                        message: NSLocalizedString("backup_uploaded_icloud", comment: "")
                                    )
                                    return
                                }
                                self?.onBackupSave(error: error)
                            }
                        })
                    }
                }
        })
        let showMasterPasswordCellItem = SettingsCellItem(
            title: NSLocalizedString("show_backup_password", comment: ""),
            action: { [weak self] in
                self?.showBackupPassword()
        })
        let autoBackupSwitcher = SettingsSwitchCellItem(
            title: NSLocalizedString("auto_backup", comment: ""),
            isOn: UserDefaults.standard.bool(forKey: Configurations.DefaultsKeys.isAutoBackupEnabled)
        ) { [weak self] isEnabled, item in
            if isEnabled {
                let icloud = ICloudStorage()
                guard icloud.isEnabled() else {
                    UserDefaults.standard.set(false, forKey: Configurations.DefaultsKeys.isAutoBackupEnabled)
                    item.switcher.isOn = false
                    self?.showICloudIsNotEnabledAlert()
                    return
                }
                
                self?.askToShowBackupPasswordAlert(onCancelHandler: {
                    item.switcher.isOn = false
                    UserDefaults.standard.set(false, forKey: Configurations.DefaultsKeys.isAutoBackupEnabled)
                }, onSavedHandler: {
                    UserDefaults.standard.set(true, forKey: Configurations.DefaultsKeys.isAutoBackupEnabled)
                    autoBackup(cloudStorage: icloud, force: true, queue: .main) { error in
                        DispatchQueue.main.async {
                            guard let error = error else {
                                return
                            }
                            
                            item.switcher.isOn = false
                            self?.showICloudIsNotEnabledAlert()
                            self?.onBackupSave(error: error)
                        }
                    }
                })
                
                return
            }
            
            UserDefaults.standard.set(isEnabled, forKey: Configurations.DefaultsKeys.isAutoBackupEnabled)
        }
        let changeMasterPassword = SettingsCellItem(
            title: NSLocalizedString("change_backup_password", comment: ""),
            action: { [weak self] in
                let changeAction = UIAlertAction(title: NSLocalizedString("change", comment: ""), style: .default, handler: { alert in
                    let authVC = AuthenticationViewController(store: self!.store, authentication: AuthenticationImpl())
                    authVC.handler = { [weak self, weak authVC] in
                        authVC?.dismiss(animated: true) {
                            let changePassword: (String, (() -> Void)?) -> Void = { password, handler in
                                let keychainStorage = KeychainStorageImpl.standart
                                do {
                                    try keychainStorage.set(value: password, forKey: .masterPassword)
                                    handler?()
                                    autoBackup(force: true) { error in
                                        if let error = error {
                                            self?.dismissAlert({
                                                self?.showErrorAlert(error: error)
                                            })
                                        }
                                    }
                                } catch {
                                    self?.showErrorAlert(error: error)
                                }
                            }
                            let alert = UIAlertController(
                                title: NSLocalizedString("change_master_password", comment: ""),
                                message: NSLocalizedString("enter_new_password", comment: ""), preferredStyle: .alert
                            )
                            
                            alert.addTextField { textField in
                                textField.isSecureTextEntry = true
                            }
                            
                            alert.addAction(UIAlertAction(title: NSLocalizedString("generate_new_password", comment: ""), style: .default, handler: { _ in
                                let password = UUID().uuidString
                                changePassword(password) {
                                    if (password.count != 0) {
                                        let copyAction = UIAlertAction(title: NSLocalizedString("copy", comment: ""), style: .default) { [weak self] _ in
                                            UIPasteboard.general.string = self?.masterPassword
                                        }
                                        
                                        let okAction = UIAlertAction(title: "Ok", style: .default, handler: nil)
                                        
                                        self?.showInfoAlert(
                                            title: NSLocalizedString("backup_password", comment: ""),
                                            message: "Backup password has changed successfuly!\nYour new backup password: \(password)",
                                            actions: [okAction, copyAction]
                                        )
                                    } else {
                                        let okAction = UIAlertAction(title: "Ok", style: .default, handler: nil)
                                        self?.showInfoAlert(
                                            title: NSLocalizedString("backup_password", comment: ""),
                                            message: "Please enter a valid backup password.",
                                            actions: [okAction]
                                        )
                                    }
                                }
                            }))
                            
                            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { [weak alert] _ in
                                guard let password = alert?.textFields?.first?.text, password.count > 0 else {
                                    let okAction = UIAlertAction(title: "Ok", style: .default, handler: nil)
                                    self?.showInfoAlert(
                                        title: NSLocalizedString("backup_password", comment: ""),
                                        message: "Please enter a valid backup password.",
                                        actions: [okAction]
                                    )
                                    return
                                }
                                
                                changePassword(password) {
                                    self?.showOKInfoAlert(
                                        title: NSLocalizedString("backup_password", comment: ""),
                                        message: NSLocalizedString("backup_password_has_changed", comment: "")
                                    )
                                }
                            }))
                            
                            self?.present(alert, animated: true)
                        }
                    }
                    
                    let authNavVC = UINavigationController(rootViewController: authVC)
                    self?.present(authNavVC, animated: true)
                })
                
                let cancelAction = UIAlertAction(title: NSLocalizedString("cancel", comment: ""), style: .cancel, handler: nil)
                
                self?.showInfoAlert(
                    title: NSLocalizedString("backup_password", comment: ""),
                    message: NSLocalizedString("change_backup_warning", comment: ""),
                    actions: [cancelAction, changeAction])
        })
        
        var supportEmail = SettingsInformativeCellItem(title: "Email", informativeText: "support@cakewallet.io", image: nil) {
            UIApplication.shared.open(URL(string:"mailto:support@cakewallet.io")!, options:[:], completionHandler: nil)
        }
        supportEmail.wantsBlue = true
        var supportTelegram = SettingsInformativeCellItem(title: "Telegram", informativeText: "Cake_Wallet", image: UIImage(named:"telegram_logo")) {
            UIApplication.shared.open(URL(string:"https://t.me/cakewallet_bot")!, options:[:], completionHandler: nil)
        }
        supportTelegram.wantsBlue = true
        var supportTwitter = SettingsInformativeCellItem(title: "Twitter", informativeText: "@CakeWalletXMR", image: UIImage(named:"twitter_logo")) {
            UIApplication.shared.open(URL(string:"https://twitter.com/CakeWalletXMR")!, options:[:], completionHandler: nil)
        }
        supportTwitter.wantsBlue = true
        var supportChangeNow = SettingsInformativeCellItem(title: "ChangeNow", informativeText: "support@changenow.io", image: UIImage(named:"changenow_logo")) {
            UIApplication.shared.open(URL(string:"mailto:support@changenow.io")!, options:[:], completionHandler: nil)
        }
        supportChangeNow.wantsBlue = true
        var supportMorph = SettingsInformativeCellItem(title: "Morph", informativeText: "support@morphtoken.com", image: UIImage(named:"morph_logo")) {
            UIApplication.shared.open(URL(string:"mailto:support@morphtoken.com")!, options:[:], completionHandler: nil)
        }
        supportMorph.wantsBlue = true
        var supportXmrTo = SettingsInformativeCellItem(title: "XMR.to", informativeText: "support@xmr.to", image: UIImage(named:"xmrto_logo")) {
            UIApplication.shared.open(URL(string:"mailto:support@xmr.to")!, options:[:], completionHandler: nil)
        }
        supportXmrTo.wantsBlue = true
        
        let termsView = SettingsCellItem(
            title: NSLocalizedString("terms", comment: ""),
            action: { [weak self] in
                let disclaimerVC = DisclaimerViewController(showingCheckbox: false)
                disclaimerVC.modalPresentationStyle = .fullScreen
//                self?.modalPresentationStyle = .fullScreen
                self?.present(disclaimerVC, animated: true)
        })
        
        sections[.nodes] = [
            currentNode
        ]
        
        sections[.wallets] = [
            displayBalances,
            fiatCurrencyCellItem,
            feePriorityCellItem,
            saveRecipientAddress
        ]
        
        if #available(iOS 13.0, *) {
            sections[.personal] = [
                changePinCellItem,
                changeLanguage,
                biometricCellItem
            ]
        } else {
            sections[.personal] = [
                changePinCellItem,
                changeLanguage,
                biometricCellItem,
                darkmodeCellItem
            ]
        }
                
        sections[.backup] = [
            showMasterPasswordCellItem,
            changeMasterPassword,
            autoBackupSwitcher,
            backupNowCellItem
        ]
        
        sections[.manualBackup] = [
            createBackupCellItem
        ]
        
        sections[.support] = [
            supportEmail,
            supportTelegram,
            supportTwitter,
            supportChangeNow,
            supportMorph,
            supportXmrTo,
            termSettingsCellItem
        ]
        
        let email = "support@cakewallet.io"
        let telegram = "https://t.me/cake_wallet"
        let twitter = "cakewalletXMR"
        let morphEmail = "contact@morphtoken.com"
        let xmrtoEmail = "support@xmr.to"
        let changeNowEmail = "support@changenow.io"
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.paragraphSpacing = 5
        paragraphStyle.lineSpacing = 5
        let attributes = [
            NSAttributedStringKey.font : UIFont.systemFont(ofSize: 15),
            NSAttributedStringKey.foregroundColor: UserInterfaceTheme.current.text,
            NSAttributedStringKey.backgroundColor: UserInterfaceTheme.current.settingCellColor,
            NSAttributedStringKey.paragraphStyle: paragraphStyle
        ]
        let attributedString = NSMutableAttributedString(
            string: String(format: "Email: %@\nTelegram: %@\nTwitter: @%@\nExchange (ChangeNow): %@\nExchange (Morph): %@\nExchange(xmr->btc): %@", email, telegram, twitter, changeNowEmail, morphEmail, xmrtoEmail),
            attributes: attributes)
        let telegramAddressRange = attributedString.mutableString.range(of: telegram)
        attributedString.addAttribute(.link, value: telegram, range: telegramAddressRange)
        let twitterAddressRange = attributedString.mutableString.range(of: String(format: "@%@", twitter))
        attributedString.addAttribute(.link, value: String(format: "https://twitter.com/%@", twitter), range: twitterAddressRange)
        let emailAddressRange = attributedString.mutableString.range(of: email)
        attributedString.addAttribute(.link, value: String(format: "mailto:%@", email), range: emailAddressRange)
        let morphAddressRange = attributedString.mutableString.range(of: morphEmail)
        attributedString.addAttribute(.link, value: String(format: "mailto:%@", morphEmail), range: morphAddressRange)
        
        let changenowAddressRange = attributedString.mutableString.range(of: changeNowEmail)
        attributedString.addAttribute(.link, value: String(format: "mailto:%@", changeNowEmail), range: changenowAddressRange)
        
        let xmrAddressRange = attributedString.mutableString.range(of: xmrtoEmail)
        attributedString.addAttribute(.link, value: String(format: "mailto:%@", morphEmail), range: xmrAddressRange)
        let contactUsCellItem = SettingsTextViewCellItem(attributedString: attributedString)
        
        if
            let dictionary = Bundle.main.infoDictionary,
            let version = dictionary["CFBundleShortVersionString"] as? String {
            contentView.footerLabel.text = String(format: "%@ %@", NSLocalizedString("version", comment: ""), version)
        }
        
        contentView.table.backgroundColor = UserInterfaceTheme.current.settingBackgroundColor
        
        contentView.table.separatorColor = UserInterfaceTheme.current.gray.dim
    }
    
    override func setTitle() {
        title = NSLocalizedString("settings", comment: "")
    }
    
    override func setBarStyle() {
        super.setBarStyle()
        navigationController?.navigationBar.backgroundColor = UserInterfaceTheme.current.settingBackgroundColor
        contentView.backgroundColor = UserInterfaceTheme.current.settingBackgroundColor
    }
    
    // MARK: StoreSubscriber
    func onStateChange(_ state: ApplicationState) {
        if let node = state.settingsState.node,
            node.uri.hashValue != displayedNodeHash {
            configureBinds()
            contentView.table.reloadData()
            displayedNodeHash = node.uri.hashValue
        }
    }
    // MARK: UITableViewDataSource
    func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard
            let section = SettingsSections(rawValue: section),
            let count = sections[section]?.count else {
                return 0
        }
        
        return count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard
            let section = SettingsSections(rawValue: indexPath.section),
            let item = sections[section]?[indexPath.row] else {
                return FlexCell()
        }
        let cell = tableView.dequeueReusableCell(withItem: item, for: indexPath)
        cell.textLabel?.font = UIFont.systemFont(ofSize: 15)
        
        cell.backgroundColor = UserInterfaceTheme.current.settingCellColor
        return cell
    }
    
    // MARK: UITableViewDelegate
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        return 50
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 60
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let section = SettingsSections(rawValue: section) else {
            return nil
        }
        
        let view = UIView(frame:
            CGRect(
                origin: .zero,
                size: CGSize(width: tableView.frame.width, height: 60)))
        let titleLabel = UILabel(frame: CGRect(origin: CGPoint(x: 20, y: 5), size: CGSize(width: view.frame.width - 20, height: view.frame.height)))
        titleLabel.font = applyFont(ofSize: 16)
        titleLabel.textColor = UserInterfaceTheme.current.textVariants.main
        view.backgroundColor =  UserInterfaceTheme.current.settingBackgroundColor

        view.addSubview(titleLabel)
        
        switch section {
        case .nodes:
            titleLabel.text = NSLocalizedString("nodes", comment: "")
        case .personal:
            titleLabel.text = NSLocalizedString("personal", comment: "")
        case .wallets:
            titleLabel.text = NSLocalizedString("wallets", comment: "")
        case .support:
            titleLabel.text = NSLocalizedString("support", comment: "")
        case .backup:
            titleLabel.text = NSLocalizedString("backup", comment: "")
        case .manualBackup:
            titleLabel.text = NSLocalizedString("manual_backup", comment: "")
        }
        
        return view
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard
            let section = SettingsSections(rawValue: indexPath.section),
            let item = sections[section]?[indexPath.row] as? ActionableCellItem else {
                tableView.deselectRow(at: indexPath, animated: true)
                return
        }
        
        item.action?()
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    private func presentChangePin() {
        let authViewController = AuthenticationViewController(store: store, authentication: AuthenticationImpl())
        authViewController.handler = { [weak self, weak authViewController] in
            authViewController?.dismiss(animated: false, completion: {
                self?.settingsFlow?.change(route: .changePin)
            })
        }
        
        present(UINavigationController(rootViewController: authViewController), animated: true)
    }
    
    private func askToShowBackupPasswordAlert(onCancelHandler: (() -> Void)? = nil, onSavedHandler: @escaping () -> Void) {
        let savedAction = UIAlertAction(title: NSLocalizedString("yes", comment: ""), style: .default) { _ in
            onSavedHandler()
        }
        let showBackupPassowrd = UIAlertAction(title: NSLocalizedString("show_password", comment: ""), style: .default) { [weak self] _ in
            self?.showBackupPassword()
            onCancelHandler?()
        }
        let cancelAction = UIAlertAction(title: NSLocalizedString("cancel", comment: ""), style: .cancel, handler: nil)
        showInfoAlert(
            title: NSLocalizedString("backup", comment: ""),
            message: NSLocalizedString("save_backup_password", comment: ""),
            actions: [savedAction, showBackupPassowrd, cancelAction]
        )
    }
    
    private func showBackupPassword() {
        let copyAction = UIAlertAction(title: NSLocalizedString("copy", comment: ""), style: .default) { [weak self] _ in
            UIPasteboard.general.string = self?.masterPassword
        }
        let cancelAction = UIAlertAction(title: NSLocalizedString("cancel", comment: ""), style: .cancel, handler: nil)
        
        let authVC = AuthenticationViewController(store: store, authentication: AuthenticationImpl())
        authVC.handler = { [weak self] in
            authVC.dismiss(animated: true) {
                self?.showInfoAlert(
                    title: NSLocalizedString("backup_password", comment: ""),
                    message: self!.masterPassword, actions: [copyAction, cancelAction]
                )
            }
        }
        
        let authNavVC = UINavigationController(rootViewController: authVC)
        present(authNavVC, animated: true)
    }
    
    private func presentChangeLanguage() {
        settingsFlow?.change(route: .changeLanguage)
    }
    
    private func toggleNightMode(isOn: Bool) {
        NotificationCenter.default.post(name: Notification.Name("changeTheme"), object: isOn ? UserInterfaceTheme.dark : UserInterfaceTheme.light )
    }
    
    private func showICloudIsNotEnabledAlert() {
        showOKInfoAlert(message: NSLocalizedString("enable_icloud", comment: ""))
    }
    
    private func onBackupSave(error: Error) {
        if case ICloudStorageError.notEnabled = error {
            showICloudIsNotEnabledAlert()
            return
        }
        
        showErrorAlert(error: error)
    }
}
