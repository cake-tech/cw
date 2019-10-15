import UIKit

final class CustomTabBarController: UITabBarController {
    private static let additionalHeight = 10 as CGFloat
    private static let titlePositionOffset = UIOffset(horizontal: 0, vertical: -5)
    private lazy var defaultTabBarHeight = {
        tabBar.frame.size.height
    }()

    override var preferredStatusBarStyle:UIStatusBarStyle {
        switch UserInterfaceTheme.current {
        case .light:
            if #available(iOS 13.0, *) {
                return .darkContent
            } else {
                // Fallback on earlier versions
                return .default
            }
        case .dark:
            return .lightContent
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setNeedsStatusBarAppearanceUpdate()
        selectedViewController?.viewWillAppear(animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        selectedViewController?.viewWillDisappear(animated)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tabBar.clipsToBounds = true
        
        view.backgroundColor = UserInterfaceTheme.current.background
        
        tabBar.backgroundColor = UserInterfaceTheme.current.background
        tabBar.layer.backgroundColor = UserInterfaceTheme.current.background.cgColor
        tabBar.barTintColor = UserInterfaceTheme.current.background
        tabBar.layer.applySketchShadow(color: UIColor(red: 52, green: 115, blue: 176), alpha: 0.2, x: 0, y: 18, blur: 44, spread: 18)
        tabBar.layer.masksToBounds = false
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        resizeTabBar()
    }
    
    private func resizeTabBar() {
        let newTabBarHeight = defaultTabBarHeight + CustomTabBarController.additionalHeight
        var newFrame = tabBar.frame
        newFrame.size.height = newTabBarHeight
        newFrame.origin.y = view.frame.size.height - newTabBarHeight
        
        tabBar.frame = newFrame
        
        tabBar.items?.forEach { item in
            item.titlePositionAdjustment = CustomTabBarController.titlePositionOffset
        }
    }
}

final class WalletFlow: NSObject, Flow, UITabBarControllerDelegate {
    enum Route {
        case start
    }
    
    var rootController: UIViewController {
        return _root
    }
    
    let _root: UITabBarController
    
    private lazy var dashboardFlow: DashboardFlow = {
        return DashboardFlow()
    }()
    
    private lazy var settingsFlow: SettingsFlow = {
       return SettingsFlow()
    }()
    
    private lazy var exchangeFlow: ExchangeFlow = {
        return ExchangeFlow()
    }()
    
    convenience override init() {
        let tabbarController = CustomTabBarController()
        self.init(rootController: tabbarController)
    }
    
    init(rootController: UITabBarController) {
        self._root = rootController
        self._root.view.backgroundColor = UserInterfaceTheme.current.background
        
        super.init()
        configureRootTabBar()
        _root.delegate = self
    }
    
    func change(route: Route) {
        switch route {
        case .start:
            _root.selectedIndex = 0
        }
    }
    
    private func configureRootTabBar() {
        _root.viewControllers = [
            dashboardFlow.rootController,
            exchangeFlow.rootController,
            settingsFlow.rootController
        ]
    }
}
