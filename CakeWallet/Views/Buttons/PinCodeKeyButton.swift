import UIKit

final class PinCodeKeyButton: UIButton {
    override var isHighlighted: Bool {
        set { }
        get { return super.isHighlighted }
    }
    var pinCode: PinCodeKeyboardKey
    
    init(pinCode: PinCodeKeyboardKey) {
        self.pinCode = pinCode
        super.init(frame: .zero)
        
        if .del == pinCode {
            setImage(UIImage(named: "delete_icon")?.withRenderingMode(.alwaysTemplate), for: .normal)
        } else {
            setTitle(pinCode.string(), for: .normal)
        }
        
        configureView()
    }
        
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func configureView() {
        showsTouchWhenHighlighted = false
        contentHorizontalAlignment = .center
        setTitleColor(UserInterfaceTheme.current.text, for: .normal)
        titleLabel?.font = applyFont(ofSize: 26, weight: .regular)
        backgroundColor = UserInterfaceTheme.current.background
        tintColor = UserInterfaceTheme.current.textVariants.main
        imageView?.tintColor = UserInterfaceTheme.current.textVariants.main
    }
    
    override func layoutSublayers(of layer: CALayer) {
        super.layoutSublayers(of: layer)
        layer.cornerRadius = frame.size.width / 2
    }
}
