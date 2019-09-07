import UIKit
import Foundation

class AnyBaseThemedViewController: AnyBaseViewController {
    var currentTheme = UserInterfaceTheme.current
    
    override init() {
        super.init()
        NotificationCenter.default.addObserver(self, selector: #selector(themeReconfigured), name: UserInterfaceTheme.notificationName, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    private func searchSubviews(_ theseViews:[UIView]) {
        for (_, thisSubview) in theseViews.enumerated() {
            if var themedView = thisSubview as? ThemedView {
                themedView.currentTheme = currentTheme
                themedView.themeChanged()
            }
            if thisSubview.subviews.count > 0 {
                searchSubviews(thisSubview.subviews)
            }
        }
    }
    
    private func configureIfNecessary() {
        let nowTheme = UserInterfaceTheme.current
        if (currentTheme != nowTheme) {
            currentTheme = nowTheme
            DispatchQueue.main.async { [weak self] in
                guard let self = self else {
                    return
                }
                self.searchSubviews(self.view.subviews)
                if var themedView = self.view as? ThemedView {
                    themedView.currentTheme = self.currentTheme
                    themedView.themeChanged()
                }
                self.view.backgroundColor = nowTheme.background
            }
            
            themeChanged()
        }
    }
   
    @objc func themeReconfigured() {
        configureIfNecessary()
    }
    
    //for overriding
    public func themeChanged() {
        return
    }
}

protocol ThemedView: UIView {
    var currentTheme:UserInterfaceTheme { get set }
    func themeChanged()
}

public struct Colorset {
    public let highlight:UIColor    //high contrast against background
    public let main:UIColor         //medium contrast against background
    public let dim:UIColor          //low contrast against background
}

protocol Theme {
    var background:UIColor { get }
    
    var text:UIColor { get }
    var textVariants:Colorset { get }
    
    var purple:Colorset { get }
    var blue:Colorset { get }
    var red:Colorset { get }
    var gray:Colorset { get }
}

enum UserInterfaceTheme: Int, Theme {
    fileprivate static let notificationName = Notification.Name("UIThemeConfigurationChanged")
    var rawValue:Int {
        switch self {
        case .light:
            return 0
        case .dark:
            return 1
        }
        
    }
    case light, dark
    
    static var current: UserInterfaceTheme {
        get {
            if let theme = UserInterfaceTheme(rawValue: UserDefaults.standard.integer(forKey: Configurations.DefaultsKeys.currentTheme)) {
                return theme
            }
            
            return .dark
        }
        set {
            let currentValue = UserInterfaceTheme(rawValue: UserDefaults.standard.integer(forKey: Configurations.DefaultsKeys.currentTheme)) ?? .dark
            if currentValue.rawValue != newValue.rawValue {
                UserDefaults.standard.set(newValue.rawValue, forKey: Configurations.DefaultsKeys.currentTheme)
                DispatchQueue.main.async {
                   NotificationCenter.default.post(name:self.notificationName, object: nil)
                }
            }
        }
    }
    
    var background: UIColor {
        switch self {
        case .light:
            return UIColor.white
        case .dark:
            return UIColor(red: 0.15, green: 0.16, blue: 0.2, alpha: 1)
        }
    }
    
    var text: UIColor {
        switch self {
        case .light:
            return UIColor.black
        case .dark:
            return UIColor.white
        }
    }
    
    var textVariants: Colorset {
        switch self {
        case .light:
            let high = UIColor(red: 0.13, green: 0.16, blue: 0.29, alpha: 1)
            let norm = UIColor(red: 0.61, green: 0.67, blue: 0.77, alpha: 1)
            let low = UIColor(red: 0.75, green: 0.79, blue: 0.84, alpha: 1)
            return Colorset(highlight:high, main:norm, dim:low)
        case .dark:
            let high = UIColor(red: 0.61, green: 0.67, blue: 0.77, alpha: 1)
            let norm = UIColor(red: 0.52, green: 0.6, blue: 0.73, alpha: 1)
            let low = UIColor(red: 0.39, green: 0.45, blue: 0.54, alpha: 1)
            return Colorset(highlight:high, main:norm, dim:low)
        }
    }
    
    var purple: Colorset {
        switch self {
        case .light:
            let high = UIColor(red: 0.54, green: 0.31, blue: 1, alpha: 1)
            let norm = UIColor(red: 0.82, green: 0.76, blue: 0.95, alpha: 1)
            let low = UIColor(red: 0.89, green: 0.83, blue: 1, alpha: 0.7)
            return Colorset(highlight:high, main:norm, dim:low)
        case .dark:
            let high = UIColor(red: 0.51, green: 0.34, blue: 1, alpha: 1)
            let norm = UIColor(red: 0.63, green: 0.47, blue: 1, alpha: 0.7)
            let low = UIColor(red: 0.72, green: 0.56, blue: 1, alpha: 0.1)
            return Colorset(highlight:high, main:norm, dim:low)
        }
    }
    
    var blue: Colorset {
        switch self {
        case .light:
            let high = UIColor(red: 0.2, green: 0.73, blue: 0.8, alpha: 1)
            let norm = UIColor(red: 0.48, green: 0.79, blue: 0.91, alpha: 0.8)
            let low = UIColor(red: 0.59, green: 0.89, blue: 1, alpha: 0.6)
            return Colorset(highlight:high, main:norm, dim:low)
        case .dark:
            let high = UIColor(red: 0.16, green: 0.73, blue: 0.96, alpha: 1)
            let norm = UIColor(red: 0.24, green: 0.75, blue: 0.94, alpha: 0.6)
            let low = UIColor(red: 0.59, green: 0.89, blue: 1, alpha: 0.1)
            return Colorset(highlight:high, main:norm, dim:low)
        }
    }
    
    var red: Colorset {
        switch self {
        case .light:
            let high = UIColor(red:0.82, green:0.26, blue:0.47, alpha:1.0)
            let norm = UIColor(red: 194, green: 78, blue: 149)
            let low = UIColor(red:216, green: 192, blue: 209)
            return Colorset(highlight:high, main:norm, dim:low)
        case .dark:
            let high = UIColor(red:0.81, green:0.16, blue:0.37, alpha:1.0)
            let norm = UIColor(red:0.76, green:0.38, blue:0.51, alpha:1.0)
            let low = UIColor(red:0.22, green:0.11, blue:0.15, alpha:1.0)
            return Colorset(highlight:high, main:norm, dim:low)
        }
    }
    
    var gray: Colorset {
        switch self {
        case .light:
            let high = UIColor(red: 0.58, green: 0.62, blue: 0.72, alpha: 1)
            let norm = UIColor(red: 0.88, green: 0.91, blue: 0.96, alpha: 1)
            let low = UIColor(red: 0.98, green: 0.98, blue: 0.99, alpha: 1)
            return Colorset(highlight:high, main:norm, dim:low)
        case .dark:
            let high = UIColor(red: 0.61, green: 0.67, blue: 0.77, alpha: 1)
            let norm = UIColor(red: 0.77, green: 0.81, blue: 0.93, alpha: 0.4)
            let low = UIColor(red: 0.85, green: 0.87, blue: 0.96, alpha: 0.1)
            return Colorset(highlight:high, main:norm, dim:low)
        }
    }
    
    var container: ContainerColorScheme {
        switch self {
        case .light:
            return ContainerColorScheme(background: .white)
        case .dark:
            return ContainerColorScheme(background: .wildDarkBlue)
        }
    }
    
    var primaryButton: ButtonColorScheme {
        switch self {
        case .light:
            return ButtonColorScheme(background: .purpleyLight, text: .black)
        case .dark:
            return ButtonColorScheme(background: .whiteSmoke, text: .vividBlue)
        }
    }
}
