import UIKit
import Foundation

protocol Themed {
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


fileprivate var currentCached:UserInterfaceTheme? = nil
enum UserInterfaceTheme: Int, Theme {
    static let notificationName = Notification.Name("UIThemeConfigurationChanged")
    var rawValue:Int {
        switch self {
        case .light:
            return 0
        case .dark:
            return 1
        }
    }
    case light, dark
    static var `default` = UserInterfaceTheme.light
    static var current: UserInterfaceTheme {
        get {
            if let cacheTest = currentCached {
                return cacheTest
            }
            if let theme = UserInterfaceTheme(rawValue: UserDefaults.standard.integer(forKey: Configurations.DefaultsKeys.currentTheme)) {
                currentCached = theme
                return theme
            }
            currentCached = self.`default`
            return self.`default`
        }
        set {
            let currentValue = UserInterfaceTheme(rawValue: UserDefaults.standard.integer(forKey: Configurations.DefaultsKeys.currentTheme)) ?? self.`default`
            if currentValue.rawValue != newValue.rawValue {
                currentCached = newValue
                UserDefaults.standard.set(newValue.rawValue, forKey: Configurations.DefaultsKeys.currentTheme)
                DispatchQueue.main.async {
                   NotificationCenter.default.post(name:self.notificationName, object: nil)
                }
            }
        }
    }
    
    var tabBar: UIColor {
        switch self {
        case .light:
            return UIColor.white
        case .dark:
            return UIColor.black
        }
    }
    
    var cardColor: UIColor {
        switch self {
        case .light:
            return UIColor(red:0.99, green:0.99, blue:0.99, alpha:1.0)
        case .dark:
            return UIColor(red:0.08, green:0.10, blue:0.15, alpha:1.0)
        }

    }
    
    var background: UIColor {
        switch self {
        case .light:
            return .white
        case .dark:
            return UIColor(red:0.04, green:0.05, blue:0.07, alpha:1.0)

        }
    }
    
    var text: UIColor {
        switch self {
        case .light:
            return UIColor(red:0.13, green:0.16, blue:0.29, alpha:1.0)
        case .dark:
            return UIColor(red:0.89, green:0.91, blue:0.97, alpha:1.0)
        }
    }
    
    var textVariants: Colorset {
        switch self {
        case .light:
            let high = UIColor(red: 0.23, green: 0.26, blue: 0.39, alpha: 1)
            let norm = UIColor(red:0.61, green:0.67, blue:0.77, alpha:1.0)
            let low = UIColor(red:0.84, green:0.87, blue:0.91, alpha:1.0)
            return Colorset(highlight:high, main:norm, dim:low)
        case .dark:
            let high = UIColor(red: 0.81, green: 0.87, blue: 0.97, alpha: 1)
            let norm = UIColor(red:0.52, green:0.61, blue:0.73, alpha:1.0)
            let low = UIColor(red:0.39, green:0.45, blue:0.53, alpha:1.0)
            return Colorset(highlight:high, main:norm, dim:low)
        }
    }
    
    var purple: Colorset {
        switch self {
        case .light:
            let high = UIColor(red:0.54, green:0.35, blue:0.98, alpha:1.0)
            let norm = UIColor(red:0.82, green:0.76, blue:0.95, alpha:1.0)
            let low = UIColor(red:0.92, green:0.88, blue:1.00, alpha:1.0)
            return Colorset(highlight:high, main:norm, dim:low)
        case .dark:
            let high = UIColor(red: 0.51, green: 0.34, blue: 1, alpha: 1)
            let norm = UIColor(red: 0.63, green: 0.47, blue: 1, alpha: 1)
            let low = UIColor(red: 0.72, green: 0.56, blue: 1, alpha: 0.1)
            return Colorset(highlight:high, main:norm, dim:low)
        }
    }
    
    var blue: Colorset {
        switch self {
        case .light:
            let high = UIColor(red:0.21, green:0.74, blue:0.95, alpha:1.0)
            let norm = UIColor(red:0.53, green:0.81, blue:0.92, alpha:1.0)
            let low = UIColor(red:0.84, green:0.95, blue:0.99, alpha:1.0)
            return Colorset(highlight:high, main:norm, dim:low)
        case .dark:
            let high = UIColor(red: 0.16, green: 0.73, blue: 0.96, alpha: 1)
            let norm = UIColor(red: 0.24, green: 0.75, blue: 0.94, alpha: 1)
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
            let low = UIColor(red: 0.95, green: 0.95, blue: 0.96, alpha: 1)
            return Colorset(highlight:high, main:norm, dim:low)
        case .dark:
            let high = UIColor(red: 0.61, green: 0.67, blue: 0.77, alpha: 1)
            let norm = UIColor(red:0.38, green:0.40, blue:0.46, alpha:1.0)
            let low = UIColor(red:0.13, green:0.15, blue:0.20, alpha:1.0)
            return Colorset(highlight:high, main:norm, dim:low)
        }
    }
}

extension UserInterfaceTheme {
    func asset(named assetName:String) -> UIImage? {
        let searchName = assetName + "_" + String(self.rawValue)
        return UIImage(named: searchName)
    }
    var settingCellColor: UIColor {
        get {
            switch self {
            case .light:
                return self.background
            case .dark:
                return self.cardColor
            }
        }
    }
    var settingBackgroundColor: UIColor {
        get {
            switch self {
            case .light:
                return self.cardColor
            case .dark:
                return self.background
            }
        }
    }
}
