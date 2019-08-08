import UIKit
import CakeWalletLib
import CakeWalletCore
import IQKeyboardManagerSwift
import ZIPFoundation
import CryptoSwift

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    var signUpFlow: SignUpFlow?
    var walletFlow: WalletFlow?
    var restoreWalletFlow: RestoreWalletFlow?
    
    var rememberedViewController: UIViewController?
    private var blurEffectView: UIVisualEffectView?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        do {
            try migrateKeychainAccessibilities(keychain: KeychainStorageImpl.standart)
        } catch {
            print("migrateKeychainAccessibilities Error")
            print(error)
        }
        
        IQKeyboardManager.shared.enable = true
        register(handler: LoadWalletHandler())
        register(handler: LoadCurrentWalletHandler())
        register(handler: CreateWalletHandler())
        register(handler: RestoreFromKeysWalletHandler())
        register(handler: RestoreFromSeedWalletHandler())
        register(handler: FetchBlockchainHeightHandler())
        register(handler: CalculateEstimatedFeeHandler())
        register(handler: FetchWalletsHandler())
        register(handler: UpdateTransactionsHandler())
        register(handler: AskToUpdateHandler())
        register(handler: ConnectToNodeHandler())
        register(handler: ReconnectToNodeHandler())
        register(handler: SaveHandler())
        register(handler: CreateTransactionHandler())
        register(handler: CommitTransactionHandler())
        register(handler: RescanHandler())
        register(handler: FetchSeedHandler())
        register(handler: SetPinHandler())
        register(handler: ChangeAutoSwitchHandler())
        register(handler: ChangeTransactionPriorityHandler())
        register(handler: ChangeCurrentNodeHandler())
        register(handler: ChangeCurrentFiatHandler())
        register(handler: ChangeBalanceDisplayHandler())
        register(handler: CheckConnectionHandler())
        register(handler: UpdateFiatPriceHandler())
        register(handler: UpdateFiatBalanceHandler())
        register(handler: UpdateSubaddressesHandler())
        register(handler: UpdateSubaddressesHistroyHandler())
        register(handler: AddNewSubaddressesHandler())
        register(handler: ChangeBiometricAuthenticationHandler())
        register(handler: ConnectToCurrentNodeHandler())
        register(handler: UpdateAccountsHandler())
        register(handler: UpdateAccountsHistroyHandler())
        register(handler: AddNewAccountHandler())
        register(handler: UpdateAccountHandler())
        register(handler: UpdateSubaddressHandler())
        
        window = UIWindow(frame: UIScreen.main.bounds)
        
        let termsOfUseAccepted = UserDefaults.standard.bool(forKey: Configurations.DefaultsKeys.termsOfUseAccepted)
        let pin = try? KeychainStorageImpl.standart.fetch(forKey: .pinCode)
        
        if !UserDefaults.standard.bool(forKey: Configurations.DefaultsKeys.masterPassword) {
            generateMasterPassword()
        }
        
        if UserDefaults.standard.bool(forKey: Configurations.DefaultsKeys.isAutoBackupEnabled) {
            autoBackup()
        }

        if !UserDefaults.standard.bool(forKey: Configurations.DefaultsKeys.walletsDirectoryPathMigrated) {
            do {
                try migrateWalletsDirectoryPath(newWalletsDirectory: "wallets")
                UserDefaults.standard.set(true, forKey: Configurations.DefaultsKeys.walletsDirectoryPathMigrated)
            } catch {
                print("error \(error)")
            }
        }
        

        if !store.state.walletState.name.isEmpty && pin != nil {
            let authController = AuthenticationViewController(store: store, authentication: AuthenticationImpl())
            let splashController = SplashViewController(store: store)
            let loadWalletHandler = LoadCurrentWalletHandler()
            
            window?.rootViewController = splashController
            
            splashController.handler = { [weak self] in
                loadWalletHandler.handle(action: WalletActions.loadCurrentWallet, store: store, handler: { action in
                    guard let action = action else {
                        return
                    }
            
                    store.dispatch(action)
                    store.dispatch(WalletActions.connectToCurrentNode)
                    
                    DispatchQueue.main.async {
                        self?.window?.rootViewController = authController
                    }
                })
            }
            
            authController.handler = { [weak self] in
                store.dispatch(SettingsState.Action.isAuthenticated)
                DispatchQueue.main.async {
                    self?.walletFlow = WalletFlow()
                    self?.walletFlow?.change(route: .start)
                    
                    self?.window?.rootViewController = self?.walletFlow?.rootController
                    
                    if !termsOfUseAccepted {
                        self?.window?.rootViewController?.present(DisclaimerViewController(), animated: false)
                    }
                }
            }
        } else {
            let navigationController = UINavigationController()
            restoreWalletFlow = RestoreWalletFlow(navigationController: navigationController)
            signUpFlow = SignUpFlow(navigationController: navigationController, restoreWalletFlow: restoreWalletFlow!)
            signUpFlow?.doneHandler = { [weak self] in
                self?.walletFlow = WalletFlow()
                self?.walletFlow?.change(route: .start)
                self?.window?.rootViewController = self?.walletFlow?.rootController
                self?.signUpFlow = nil
            }
            window?.rootViewController = signUpFlow?.rootController
            signUpFlow?.change(route: .disclaimer)
        }
        
        window?.makeKeyAndVisible()
        setAppearance()
        return true
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        guard
            let viewController = window?.rootViewController,
            !biometricIsShown && self.blurEffectView == nil else {
                return
        }
        guard
            let _ = window?.rootViewController,
            self.blurEffectView == nil else {
                return
        }
        
        let vc: UIViewController
        
        if let presentedVC = viewController.presentedViewController {
            vc = presentedVC
        } else {
            vc = viewController
        }
        
        let blurEffect = UIBlurEffect(style: UIBlurEffectStyle.light)
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        self.blurEffectView = blurEffectView
        blurEffectView.frame = vc.view.bounds
        blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        vc.view.addSubview(blurEffectView)
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers,
        // and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        guard
            walletFlow != nil
                && !store.state.walletState.name.isEmpty
                && !(UIApplication.topViewController() is AuthenticationViewController) else {
                    return
        }
        
        let authScreen = AuthenticationViewController(store: store, authentication: AuthenticationImpl())
        authScreen.modalPresentationStyle = .overFullScreen
        UIApplication.topViewController()?.present(authScreen, animated: false)
        authScreen.handler = { [weak authScreen] in
            DispatchQueue.main.async {
                authScreen?.dismiss(animated: true)
            }
        }
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        if let blurEffectView = self.blurEffectView {
            blurEffectView.removeFromSuperview()
            self.blurEffectView = nil
        }
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    
    
    private func setAppearance() {
        UITabBar.appearance().layer.borderWidth = 0.0

        UITabBar.appearance().backgroundColor = .white
        UITabBar.appearance().shadowImage = UIImage()
        UITabBar.appearance().backgroundImage = UIImage()
        UITabBar.appearance().layer.borderColor = UIColor.clear.cgColor
        UITabBar.appearance().clipsToBounds = true
//        UITabBar.appearance().tintColor = .vividBlue
//        UITabBar.appearance().unselectedItemTintColor = UIColor(hex: 0xC0D4E2)

        UINavigationBar.appearance().tintColor = .black
        UINavigationBar.appearance().backgroundColor = .clear

//        UINavigationItem
//        UINavigationBar.appearance()
        
//        UINavigationBar.appearance().backIndicatorImage = backImage
//        UINavigationBar.appearance().backIndicatorTransitionMaskImage = backImage
//        UIBarButtonItem.appearance().setTitleTextAttributes([NSAttributedStringKey.foregroundColor: UIColor.clear], for: .normal)
//        UIBarButtonItem.appearance().setTitleTextAttributes([NSAttributedStringKey.foregroundColor: UIColor.clear], for: .highlighted)

//        UINavigationBar.appearance().backItem?.title = ""
//        UINavigationBar.appearance().backgroundColor = .clear
        
//        UINavigationBar.appearance().isTranslucent = true
        UINavigationBar.appearance().setBackgroundImage(UIImage(), for: .default)
        UINavigationBar.appearance().shadowImage = UIImage()
        
        UINavigationBar.appearance().titleTextAttributes = [
            NSAttributedStringKey.foregroundColor: UIColor.black,
            NSAttributedStringKey.font: UIFont.systemFont(ofSize: 16)
        ]
    }
    
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {
        let filename = url.lastPathComponent
        let cancelAction = UIAlertAction(title: NSLocalizedString("cancel", comment: ""), style: .cancel, handler: nil)
        let restore = UIAlertAction(title: "Restore", style: .default) { action in
            let alert = UIAlertController(title: "Restore from backup", message: "Enter password", preferredStyle: .alert)
            
            alert.addTextField { textField in
                textField.isSecureTextEntry = true
            }
            
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { [weak alert] _ in
                guard let password = alert?.textFields?.first?.text else {
                    return
                }
                
                UIApplication.topViewController()?.showSpinnerAlert(withTitle: "Restoring from backup") { [weak self] spinner in
                    do {
                        let backup = BackupServiceImpl()
                        try backup.import(from: url, withPassword: password)
                        let handler = LoadCurrentWalletHandler()
                        handler.handle(action: WalletActions.loadCurrentWallet, store: store, handler: { action in
                            DispatchQueue.main.async {
                                guard let action = action else {
                                    return
                                }
                                
                                store.dispatch(action)
                                store.dispatch(WalletActions.connectToCurrentNode)
                                
                                spinner.dismiss(animated: true) {
                                    if
                                        let action = action as? ApplicationState.Action,
                                        case let .changedError(_error) = action,
                                        let error = _error {
                                        
                                        UIApplication.topViewController()?.showErrorAlert(error: error)
                                        return
                                    }
                                    
                                    
                                    self?.walletFlow = WalletFlow()
                                    self?.walletFlow?.change(route: .start)
                                    
                                    self?.window?.rootViewController = self?.walletFlow?.rootController
                                }
                            }
                        })
                    } catch {
                        spinner.dismiss(animated: true) {
                            UIApplication.topViewController()?.showErrorAlert(error: error)
                        }
                    }
                }
            }))
            
            UIApplication.topViewController()?.present(alert, animated: true)
        }
        UIApplication.topViewController()?.showInfoAlert(
            title: "Restore from backup",
            message: "Are you sure that want to restore the app from backup - \(filename)",
            actions: [cancelAction, restore])
        return true
    }
}

extension UIApplication {
    class func topViewController(controller: UIViewController? = UIApplication.shared.keyWindow?.rootViewController) -> UIViewController? {
        if let navigationController = controller as? UINavigationController {
            return topViewController(controller: navigationController.visibleViewController)
        }
        if let tabController = controller as? UITabBarController {
            if let selected = tabController.selectedViewController {
                return topViewController(controller: selected)
            }
        }
        if let presented = controller?.presentedViewController {
            return topViewController(controller: presented)
        }
        return controller
    }
}
