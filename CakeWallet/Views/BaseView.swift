import UIKit

class BaseView: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        configureView()
    }
    
    required init() {
        super.init(frame: CGRect.zero)
        configureView()
        backgroundColor = UserInterfaceTheme.current.background
    }
    
    @available(*, unavailable)
    required init(coder aDecoder: NSCoder) {
        fatalError("This class does not support NSCoding")
    }
    
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        configureConstraints()
    }
    
    override func configureView() {
        super.configureView()
    }

    var currentTheme:UserInterfaceTheme {
        get {
            return UserInterfaceTheme.current
//            if #available(iOS 13.0, *) {
//                switch traitCollection.userInterfaceStyle {
//                case .light:
//                    return UserInterfaceTheme.light
//                case .dark:
//                    return UserInterfaceTheme.dark
//                default:
//                    return UserInterfaceTheme.default
//                }
//            } else {
//                return UserInterfaceTheme.current
//            }
        }
    }
}

extension UIView {
    @objc
    func configureView() {}
    @objc
    func configureConstraints() {}
}
