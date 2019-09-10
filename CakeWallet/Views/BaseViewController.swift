import UIKit
import FlexLayout
import CakeWalletLib
import CakeWalletCore
import VisualEffectView

extension UIImage {
    class func imageWithColor(color: UIColor, size: CGSize) -> UIImage {
        let rect: CGRect = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        color.setFill()
        UIRectFill(rect)
        let image: UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return image
    }
}

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
        setBarStyle()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setNeedsStatusBarAppearanceUpdate()
        setBarStyle()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        guard let navController = self.navigationController else {
            return
        }
        navController.navigationBar.titleTextAttributes = [NSAttributedStringKey.font:applyFont(ofSize: 16)]
        setBarStyle()
    }
    
    public func setBarStyle() {
        guard let navController = self.navigationController else {
            return
        }
        switch UserInterfaceTheme.current {
        case .dark:
            navController.navigationBar.barStyle = UIBarStyle.black
        case .light:
            navController.navigationBar.barStyle = UIBarStyle.default
        }
        navigationController?.navigationBar.backgroundColor = UserInterfaceTheme.current.background
        contentView.backgroundColor = UserInterfaceTheme.current.background
        navigationController?.navigationItem.backBarButtonItem?.tintColor = UserInterfaceTheme.current.text
        
        if let tabBar = tabBarController?.tabBar {
            tabBar.isTranslucent = false
            tabBar.barTintColor = UserInterfaceTheme.current.tabBar
//            tabBar.backgroundImage = UIImage.imageWithColor(color: .black, size:tabBar.frame)
            tabBar.tintColor = UserInterfaceTheme.current.blue.highlight
        }
    }
    
    func setTitle() {}
}
