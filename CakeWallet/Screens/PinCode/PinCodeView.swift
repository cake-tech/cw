import UIKit
import FlexLayout

final class PinCodeView: BaseFlexView {
    let titleLabel: UILabel
    let pinPasswordKeyboard: PinCodeKeyboard
    let pinCodesView: PinCodeIndicatorsView
    let useSixPin: UIButton
    required init() {
        titleLabel = UILabel.withLightText(fontSize: 24)
        pinPasswordKeyboard = PinCodeKeyboard()
        pinCodesView = PinCodeIndicatorsView()
        useSixPin = UIButton(type: .system)
        useSixPin.isHidden = true
        super.init()
    }
    
    override func configureView() {
        super.configureView()
        titleLabel.text = NSLocalizedString("enter_your_pin", comment: "")
        titleLabel.font = applyFont(ofSize: 24, weight: .regular)
        titleLabel.numberOfLines = 0
        titleLabel.textAlignment = .center
        let attributes = [ NSAttributedStringKey.foregroundColor : UserInterfaceTheme.current.textVariants.main, NSAttributedStringKey.font: UIFont(name: "Lato-Regular", size: 16)]
        useSixPin.setTitleColor(UserInterfaceTheme.current.textVariants.main, for: .normal)
        useSixPin.setAttributedTitle(NSAttributedString(string: NSLocalizedString("use_6_pin", comment: ""), attributes: attributes), for: .normal)
    }
    
    override func configureConstraints() {
        rootFlexContainer.flex.define { flex in
            let pinPasswordKeyboardContainer = UIView()
            
            flex.addItem(titleLabel).marginTop(20%)
            flex.addItem(pinCodesView).marginTop(25).width(100%).alignItems(.center)
            flex.addItem(useSixPin).marginTop(45).alignSelf(.center)
            
            pinPasswordKeyboardContainer.flex
                .justifyContent(.end).grow(1)
                .marginTop(25).marginBottom(10.8%)
                    .addItem(pinPasswordKeyboard).marginLeft(10.8%).marginRight(10.8%)
            flex.addItem(pinPasswordKeyboardContainer)
        }
    }
}
