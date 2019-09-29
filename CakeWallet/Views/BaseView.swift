import UIKit

class BaseView: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        configureView()
    }
    
    required init() {
        super.init(frame: CGRect.zero)
        configureView()
        if #available(iOS 13.0, *) {
            overrideUserInterfaceStyle = UserInterfaceTheme.current.asStyle
        }
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
        backgroundColor = UserInterfaceTheme.current.background
    }
}

extension UIView {
    @objc
    func configureView() {}
    @objc
    func configureConstraints() {}
}
