import UIKit
import FlexLayout

final class PinCodeIndicatorView: BaseView, ThemedView {
    var currentTheme: UserInterfaceTheme = UserInterfaceTheme.current
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
        backgroundColor = currentTheme.background
        
        innerCircleView.layer.borderWidth = 0.7
        innerCircleView.layer.borderColor = currentTheme.purple.main.cgColor
        innerCircleView.backgroundColor = currentTheme.purple.dim
    }
    
    override func configureConstraints() {
        rootFlexContainer.flex.justifyContent(.center).alignItems(.center).height(100%).width(100%).addItem(innerCircleView).width(10).height(10)
    }
    
    func themeChanged() {
        backgroundColor = currentTheme.background
        innerCircleView.layer.borderColor = currentTheme.purple.main.cgColor
        innerCircleView.backgroundColor = currentTheme.purple.dim
        
    }
    
    func fill() {
        innerCircleView.backgroundColor = currentTheme.purple.main
        innerCircleView.layer.borderColor = currentTheme.purple.highlight.cgColor
    }
    
    func clear() {
        innerCircleView.layer.borderColor = currentTheme.purple.main.cgColor
        innerCircleView.backgroundColor = currentTheme.purple.dim
    }
}
