import UIKit
import FlexLayout

final class PinCodeIndicatorView: BaseView {
    let rootFlexContainer: UIView
    let innerCircleView: UIView
    
    required init() {
        rootFlexContainer = UIView()
        innerCircleView = UIView()
        super.init()
    }
    
    override func configureView() {
        super.configureView()
        innerCircleView.layer.cornerRadius = 5
        addSubview(rootFlexContainer)
        addSubview(innerCircleView)
        
        innerCircleView.layer.borderWidth = 0.7
        innerCircleView.layer.borderColor = UserInterfaceTheme.current.purple.main.cgColor
        innerCircleView.layer.backgroundColor = UserInterfaceTheme.current.purple.dim.cgColor
    }
    
    override func configureConstraints() {
        rootFlexContainer.flex.justifyContent(.center).alignItems(.center).height(100%).width(100%).addItem(innerCircleView).width(10).height(10)
    }
    
    func fill() {
        innerCircleView.layer.backgroundColor = UserInterfaceTheme.current.purple.main.cgColor
        innerCircleView.layer.borderColor = UserInterfaceTheme.current.purple.main.cgColor
    }
    
    func clear() {
        innerCircleView.layer.borderColor = UserInterfaceTheme.current.purple.main.cgColor
        innerCircleView.backgroundColor = UserInterfaceTheme.current.purple.dim
    }
}
