import UIKit
import FlexLayout
import CakeWalletLib
import CakeWalletCore
import VisualEffectView

class BaseViewController<View: BaseView>: AnyBaseViewController {
    var contentView: View { return view as! View }
    
    override var preferredStatusBarStyle:UIStatusBarStyle {
        switch UserInterfaceTheme.current {
        case .light:
                return .default
        case .dark:
                return .lightContent
        }
    }
    
    override init() {
        super.init()
        setTitle()
        NotificationCenter.default.addObserver(forName: UserInterfaceTheme.notificationName, object:nil, queue:nil) { [weak self] notification in
            self?.loadView()
            self?.setBarStyle()
            if let conformingSelf = self as? Themed {
                conformingSelf.themeChanged()
            }
        }
        NotificationCenter.default.addObserver(forName: Notification.Name("langChanged"), object: nil, queue: nil) { [weak self] notification in
            self?.loadView()
            
            if let title = self?.title {
                self?.title = title
            }
            
            if let storeSub = self as? AnyStoreSubscriber {
                storeSub._onStateChange(store.state)
            }
        }
    }
    
    override func loadView() {
        super.loadView()
        view = View()
        configureBinds()
        setTitle()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setNeedsStatusBarAppearanceUpdate()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        guard let navController = self.navigationController else {
            return
        }
        setBarStyle()
        navController.navigationBar.titleTextAttributes = [NSAttributedStringKey.font: applyFont(ofSize: 16)]
    }
    
    private func setBarStyle() {
        guard let navController = self.navigationController else {
            return
        }
        switch UserInterfaceTheme.current {
        case .dark:
            navController.navigationBar.barStyle = UIBarStyle.black
        case .light:
            navController.navigationBar.barStyle = UIBarStyle.default
        }
    }
    
    func setTitle() {}
}
