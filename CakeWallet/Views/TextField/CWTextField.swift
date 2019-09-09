import UIKit

class CWTextField: UITextField {
    private static let bottomBorderHeight = 1.5 as CGFloat
    private let fontSize: CGFloat
    private var isBorderAdded: Bool
    let bottomBorder: CALayer
    var insetX = 0 as CGFloat
    var insetY = 10 as CGFloat
    
    required init(placeholder: String = "", fontSize: CGFloat = 18) {
        self.fontSize = fontSize
        isBorderAdded = false
        bottomBorder = CALayer()
        super.init(frame: CGRect(origin: .zero, size: CGSize(width: 0, height: 75)))
        setPlaceholder(placeholder)
        configureView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fontSize = 18
        isBorderAdded = false
        bottomBorder = CALayer()
        super.init(coder: aDecoder)
        configureView()
    }
    
    override init(frame: CGRect) {
        fontSize = 18
        isBorderAdded = false
        bottomBorder = CALayer()
        super.init(frame: frame)
        configureView()
    }
    
    override func configureView() {
        super.configureView()
        borderStyle = .none
        bottomBorder.backgroundColor = UserInterfaceTheme.current.gray.main.cgColor
        font = applyFont(ofSize: fontSize)
        layer.addSublayer(bottomBorder)
    }
    
    override func textRect(forBounds bounds: CGRect) -> CGRect {
        let dx = leftView?.frame.size.width ?? insetX
        let rightOffset = (rightView?.frame.size.width ?? 0)
        var frame = bounds.insetBy(dx: dx, dy: insetY)
        frame.size.width = frame.size.width - rightOffset
        return frame
    }

    override func editingRect(forBounds bounds: CGRect) -> CGRect {
        let dx = leftView?.frame.size.width ?? insetX
        let rightOffset = (rightView?.frame.size.width ?? 0)
        var frame = bounds.insetBy(dx: dx, dy: insetY)
        frame.size.width = frame.size.width - rightOffset
        return frame
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        updateLayoutBottomBorder()
    }
    
    func setPlaceholder(_ placeholder: String) {
        attributedPlaceholder = NSAttributedString(
            string: placeholder,
            attributes: [
                NSAttributedString.Key.foregroundColor: UserInterfaceTheme.current.textVariants.dim,
                NSAttributedStringKey.font: UIFont(name: "Lato-Regular", size: fontSize)!
            ]
        )
    }
    
    func updateLayoutBottomBorder() {
        let y = frame.size.height - CWTextField.bottomBorderHeight
        bottomBorder.frame = CGRect(
            origin: CGPoint(x: 0, y: y),
            size: CGSize(width: self.frame.size.width, height: CWTextField.bottomBorderHeight))
    }
}
