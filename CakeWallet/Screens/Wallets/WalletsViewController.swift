import UIKit
import CakeWalletLib
import CakeWalletCore
import CWMonero

//https://stackoverflow.com/a/39917334
extension UIView {

    func mask(withRect rect: CGRect, inverse: Bool = false) {
        let path = UIBezierPath(rect: rect)
        let maskLayer = CAShapeLayer()

        if inverse {
            path.append(UIBezierPath(rect: self.bounds))
            maskLayer.fillRule = kCAFillRuleEvenOdd
        }

        maskLayer.path = path.cgPath

        self.layer.mask = maskLayer
    }

    func mask(withPath path: UIBezierPath, inverse: Bool = false) {
        let path = path
        let maskLayer = CAShapeLayer()

        if inverse {
            path.append(UIBezierPath(rect: self.bounds))
            maskLayer.fillRule = kCAFillRuleEvenOdd
        }

        maskLayer.path = path.cgPath

        self.layer.mask = maskLayer
    }
}

protocol WalletActionsPresentable {
    func presentSeed(for wallet: WalletIndex, withConfig walletConfig: WalletConfig)
}

extension WalletActionsPresentable where Self: AnyBaseViewController {
    func presentKeys() {
        let authController = AuthenticationViewController(store: store, authentication: AuthenticationImpl())
        let navController = UINavigationController(rootViewController: authController)
        authController.onDismissHandler = onDismissHandler
        
        authController.handler = { [weak authController] in
            authController?.dismiss(animated: true) {
//                walletsFlow?.change(route: .showKeys)
            }
        }
        
        present(navController, animated: true)
    }
}

struct WalletCellItem: CellItem {
    let wallet: WalletIndex
    let isCurrent: Bool
    var onLoadHandler: ((WalletIndex) -> Void)?
    var onShowSeedHandler: ((WalletIndex) -> Void)?
    var onShowKeysHandler: ((WalletIndex) -> Void)?
    
    init(wallet: WalletIndex, isCurrent: Bool) {
        self.wallet = wallet
        self.isCurrent = isCurrent
    }
    
    init(wallet: WalletIndex, isCurrent: Bool, onLoadHandler: ((WalletIndex) -> Void)?, onShowSeedHandler: ((WalletIndex) -> Void)?, onShowKeysHandler: ((WalletIndex) -> Void)?) {
        self.wallet = wallet
        self.isCurrent = isCurrent
        self.onLoadHandler = onLoadHandler
        self.onShowSeedHandler = onShowSeedHandler
        self.onShowKeysHandler = onShowKeysHandler
    }
    
    func setup(cell: WalletUITableViewCell) {
        cell.configure(wallet: wallet, isCurrent: isCurrent)
        cell.onLoadHandler = onLoadHandler
        cell.onShowKeysHandler = onShowKeysHandler
        cell.onShowSeedHandler = onShowSeedHandler
    }
}

final class WalletsViewController: BaseViewController<WalletsView>, UITableViewDelegate, UITableViewDataSource, StoreSubscriber {
    let navigationTitleView: WalletsNavigationTitle
    weak var walletsFlow: WalletsFlow?
    private lazy var signUpFlow: SignUpFlow? = { [weak self] in
        let navigationController: UINavigationController
        
        if let _navigationController = self?.navigationController {
            navigationController = _navigationController
            
        } else {
            navigationController = UINavigationController()
        }
        
        let restoreWalletFlow = RestoreWalletFlow(navigationController: navigationController)
        let signUpFlow = SignUpFlow(navigationController: navigationController, restoreWalletFlow: restoreWalletFlow)
        
        signUpFlow.doneHandler = { [weak self] in
            self?.dismiss(animated: true) {
                self?.signUpFlow = nil
            }
        }
        
        return signUpFlow
    }()
    
    private var wallets: [WalletCellItem]
    private var store: Store<ApplicationState>
    private var currentWallet: WalletIndex {
        return WalletIndex(name: store.state.walletState.name, type: store.state.walletState.walletType)
    }
    
    init(store: Store<ApplicationState>, walletsFlow: WalletsFlow?) {
        self.store = store
        self.walletsFlow = walletsFlow
        wallets = []
        navigationTitleView = WalletsNavigationTitle()
        super.init()
    }
    
    override func configureBinds() {
        contentView.walletsTableView.delegate = self
        contentView.walletsTableView.dataSource = self
        contentView.walletsTableView.register(items: [WalletCellItem.self])
        contentView.createWalletButton.addTarget(self, action: #selector(createAction), for: .touchUpInside)
        contentView.restoreWalletButton.addTarget(self, action: #selector(restoreAction), for: .touchUpInside)
        navigationTitleView.switchHandler = { [weak self] in
            self?.dismiss(animated: true)
        }
        
        insertNavigationItems()
        
        contentView.walletsTableView.separatorStyle = .none
        
        store.dispatch(WalletsActions.fetchWallets)
    }
    
    func onStateChange(_ state: ApplicationState) {
        updateWallets(state.walletsState.wallets)
        updateCurrentWallet()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let nameLabel = UILabel(text: currentWallet.name)
        nameLabel.font = UIFont(name: "Lato-Semibold", size: 18)
        navigationItem.titleView = nameLabel
        if let naviBar =
            navigationController?.navigationBar {
            naviBar.layer.masksToBounds = false
            naviBar.mask(withRect:CGRect(x: naviBar.bounds.origin.x, y: naviBar.bounds.origin.y, width: naviBar.bounds.size.width, height: naviBar.bounds.height+20))
                 naviBar.applyNavigationBarShadow()
            naviBar.applyNavigationBarShadow()
        }
     
        store.subscribe(self, onlyOnChange: [
            \ApplicationState.walletsState,
            \ApplicationState.walletState
            ])
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.navigationBar.layer.masksToBounds = true
        store.unsubscribe(self)
    }
    
    private func insertNavigationItems() {
        let closeButton = UIButton(type:.custom)
        closeButton.layer.masksToBounds = false
        closeButton.setImage(UIImage(named:"close_icon_white")?.withRenderingMode(.alwaysTemplate), for: .normal)
        closeButton.layer.cornerRadius = 11
        closeButton.imageEdgeInsets = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
        closeButton.layer.backgroundColor = UserInterfaceTheme.current.gray.dim.cgColor
        closeButton.imageView?.tintColor = UserInterfaceTheme.current.text
        closeButton.addTarget(self, action: #selector(dismissAction), for: .touchDown)
        let backButton = UIBarButtonItem(customView: closeButton)
        navigationItem.leftBarButtonItem = backButton
    }
    
    @objc
    private func dismissAction() {
        dismiss(animated: true) { [weak self] in
            self?.onDismissHandler?()
        }
    }
    
    // MARK: UITableViewDataSource
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return wallets.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let wallet = wallets[indexPath.row]
        let cell = tableView.dequeueReusableCell(withItem: wallet, for: indexPath)
        cell.textLabel?.font = UIFont(name: "Lato-SemiBold", size: 18)
        
        wallet.wallet != wallets.last?.wallet ? cell.addSeparator() : cell.removeSeparator()
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let wallet = wallets[indexPath.row]
        presentMenu(for: wallet)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return WalletUITableViewCell.height
    }
    
    private func updateWallets(_ wallets: [WalletIndex]) {
        self.wallets = wallets.map {
            let isCurrent = $0.name == currentWallet.name && $0.type == currentWallet.type
            var walletItem = WalletCellItem(wallet: $0, isCurrent: isCurrent)
            walletItem.onLoadHandler = { [weak self] wallet in
                self?.loadWallet(wallet)
            }
            walletItem.onShowSeedHandler = { [weak self] wallet in
                self?.showSeed(for: wallet)
            }
            walletItem.onShowKeysHandler = { [weak self] wallet in
                self?.showKeys(for: wallet)
            }
            return walletItem
        }
        
        let tableViewHeigth = WalletUITableViewCell.height * CGFloat(wallets.count)
        contentView.walletsTableView.reloadData()
        contentView.walletsTableView.flex.height(tableViewHeigth).markDirty()
        contentView.walletsCardView.flex.markDirty()
        contentView.rootFlexContainer.flex.layout(mode: .adjustHeight)
        contentView.layoutSubviews()
    }
    
    private func updateCurrentWallet() {
        wallets = wallets.map {
            let isCurrent = $0.wallet.name == currentWallet.name && $0.wallet.type == currentWallet.type
            return WalletCellItem(
                wallet: $0.wallet,
                isCurrent: isCurrent,
                onLoadHandler: $0.onLoadHandler,
                onShowSeedHandler: $0.onShowSeedHandler,
                onShowKeysHandler: $0.onShowKeysHandler)
        }
        
        if navigationTitleView.title != store.state.walletState.name {
            navigationTitleView.title = store.state.walletState.name
        }
        
        contentView.walletsTableView.reloadData()
        
        contentView.walletsTableView.flex.markDirty()
        contentView.rootFlexContainer.flex.layout(mode: .adjustHeight)
    }
    
    private func loadWallet(_ wallet: WalletIndex) {
        let title = NSLocalizedString("loading_wallet", comment: "")
            + " - "
            + wallet.name
        
        let authController = AuthenticationViewController(store: store, authentication: AuthenticationImpl())
        let navController = UINavigationController(rootViewController: authController)
        authController.onDismissHandler = onDismissHandler
        authController.handler = { [weak authController, weak self] in
            let cancelAction = UIAlertAction(title: NSLocalizedString("cancel", comment: ""), style: .cancel, handler: nil)
            
            authController?.dismiss(animated: true) {
                self?.showSpinnerAlert(withTitle: title) { alert in
                    self?.store.dispatch(WalletActions.load(
                        withName: wallet.name,
                        andType: wallet.type,
                        handler: {
                            alert.dismiss(animated: true) {
                                if  let error = self?.store.state.error {
                                    self?.showInfoAlert(title: nil, message: error.localizedDescription, actions: [cancelAction])
                                    return
                                }

                                self?.dismiss(animated: true) {
                                    self?.onDismissHandler?()
                                }
                            }
                    }))
                }
            }
        }
        
        present(navController, animated: true)
    }
    
    private func showSeed(for wallet: WalletIndex) {
        let authController = AuthenticationViewController(store: store, authentication: AuthenticationImpl())
        let navController = UINavigationController(rootViewController: authController)
        authController.onDismissHandler = onDismissHandler
        authController.handler = { [weak authController, weak self] in
            do {
                let gateway = MoneroWalletGateway()
                let walletURL = gateway.makeConfigURL(for: wallet.name)
                let walletConfig = try WalletConfig.load(from: walletURL)
                let seed = try gateway.fetchSeed(for: wallet)
                
                
                authController?.dismiss(animated: true) {
                    self?.walletsFlow?.change(route: .showSeed(wallet: wallet.name, date: walletConfig.date, seed: seed))
                }
                
            } catch {
                print(error)
                authController?.showErrorAlert(error: error)
            }
        }
        
        present(navController, animated: true)
    }
    
    private func switchOptions(for walletItem: WalletCellItem) {
        for section in 0..<contentView.walletsTableView.numberOfSections {
            for row in 0..<contentView.walletsTableView.numberOfRows(inSection: section) {
                guard let cell = contentView.walletsTableView.cellForRow(at: IndexPath(row: row, section: section)) as? WalletCellItem.CellType else {
                    continue
                }
                
                contentView.walletsTableView.beginUpdates()
                if walletItem.wallet == wallets[row].wallet {
                    cell.switchOptions()
                } else {
                    cell.hideOptions()
                }
                contentView.walletsTableView.flex.markDirty()
                contentView.rootFlexContainer.flex.layout()
                contentView.walletsTableView.endUpdates()
            }
        }
    }
    
    private func presentMenu(for walletItem: WalletCellItem) {
        let alertViewController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let cancelAction = UIAlertAction(title: NSLocalizedString("cancel", comment: ""), style: .cancel)
        let showSeedAction = UIAlertAction(title: NSLocalizedString("show_seed", comment: ""), style: .default) { [weak self] _ in
            self?.showSeed(for: walletItem.wallet)
        }
        
        if  walletItem.wallet != currentWallet {
            let loadWalletAction = UIAlertAction(title: NSLocalizedString("load_wallet", comment: ""), style: .default) { [weak self] _ in
                self?.loadWallet(walletItem.wallet)
            }
            let removeAction = UIAlertAction(title: NSLocalizedString("remove", comment: ""), style: .destructive) { [weak self] _ in
                self?.askToRemove(wallet: walletItem.wallet)
            }
            
            alertViewController.addAction(loadWalletAction)
            alertViewController.addAction(showSeedAction)
            alertViewController.addAction(removeAction)
        } else {
            let rescanAction = UIAlertAction(title: NSLocalizedString("rescan", comment: ""), style: .default) { [weak self] _ in
                self?.walletsFlow?.change(route: .rescan)
            }
            let showKeysAction = UIAlertAction(title: NSLocalizedString("show_keys", comment: ""), style: .default) { [weak self] _ in
                self?.showKeys(for: walletItem.wallet)
            }
            
            alertViewController.addAction(showSeedAction)
            alertViewController.addAction(showKeysAction)
            alertViewController.addAction(rescanAction)
        }
        
        alertViewController.addAction(cancelAction)
        DispatchQueue.main.async {
            self.present(alertViewController, animated: true)
        }
    }
    
    private func showKeys(for wallet: WalletIndex) {
        let authController = AuthenticationViewController(store: store, authentication: AuthenticationImpl())
        let navController = UINavigationController(rootViewController: authController)
        authController.onDismissHandler = onDismissHandler
        authController.handler = { [weak authController] in
            authController?.dismiss(animated: true) {
                self.walletsFlow?.change(route: .showKeys)
            }
        }
        
        present(navController, animated: true)
    }
    
    private func askToRemove(wallet: WalletIndex) {
        let removeAction = UIAlertAction(title: NSLocalizedString("remove", comment: ""), style: .default) { _ in
            self.remove(wallet: wallet)
        }
        let cancelAction = UIAlertAction(title: NSLocalizedString("cancel", comment: ""), style: .cancel, handler: nil)
        
        showInfoAlert(
            title: NSLocalizedString("remove", comment: "").capitalized,
            message: String(format: NSLocalizedString("ask_to_remove_message", comment: ""), wallet.name),
            actions: [removeAction, cancelAction]
        )
    }
    
    private func remove(wallet: WalletIndex) {
        let authController = AuthenticationViewController(store: store, authentication: AuthenticationImpl())
        let navController = UINavigationController(rootViewController: authController)
        authController.onDismissHandler = onDismissHandler
        authController.handler = { [weak authController, weak self] in
            authController?.dismiss(animated: true) {
                let title = NSLocalizedString("removing_wallet", comment: "")
                    + " - "
                    + wallet.name
                self?.showSpinnerAlert(withTitle: title) { alert in
                    do {
                        let gateway = MoneroWalletGateway()
                        try gateway.remove(withName: wallet.name)
                        alert.dismiss(animated: true)
                    } catch {
                        alert.dismiss(animated: true) {
                            self?.showErrorAlert(error: error)
                        }
                    }
                    
                    self?.store.dispatch(
                        WalletsActions.fetchWallets
                    )
                }
            }
        }
        
        present(navController, animated: true)
    }
    
    @objc
    private func createAction() {
        signUpFlow?.change(route: .createWallet)
    }
    
    @objc
    private func restoreAction() {
        signUpFlow?.restoreWalletFlow.change(route: .root)
    }
}


