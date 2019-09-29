import UIKit
import FlexLayout

final class WelcomeFlowCardView: BaseFlexView {
    let contentHolder: UIView
    let imageView: UIView
    
    let textHolder: UIView
    let title: UILabel
    let descriptionText: UILabel
    
    let separatorView: UIView
    let button: UIButton
    let buttonText: UILabel
    let textColor: UIColor
    
    required init(imageView: UIView, titleText: String, descriptionText: String, textColor: UIColor) {
        contentHolder = UIView()
        self.imageView = imageView
        
        textHolder = UIView()
        title = UILabel(text: titleText)
        self.textColor = textColor
        self.descriptionText = UILabel(text: descriptionText)
        
        separatorView = UIView()
        button = UIButton()
        buttonText = UILabel(text: "Next")
        
        super.init()
    }
    
    required init() {
        fatalError("init() has not been implemented")
    }
    
    override func configureView() {
        super.configureView()
        
        let titleFontSize = adaptiveLayout.getFontSize(forLarge: 23, forBig: 21, defaultSize: 20)
        let descriptionFontSize = adaptiveLayout.getFontSize(forLarge: 17, forBig: 16, defaultSize: 16)
        let buttonFontSize = adaptiveLayout.getFontSize(forLarge: 19, forBig: 18, defaultSize: 17)
        
        title.font = applyFont(ofSize: titleFontSize, weight: .semibold)
        title.textColor = textColor
        title.numberOfLines = 1
        
        descriptionText.font = applyFont(ofSize: descriptionFontSize)
        descriptionText.textColor = UserInterfaceTheme.current.textVariants.highlight
        descriptionText.numberOfLines = 2
        descriptionText.textAlignment = .center
        
        buttonText.font = applyFont(ofSize: buttonFontSize, weight: .semibold)
        buttonText.textColor = textColor
    }

    override func configureConstraints() {
        rootFlexContainer.layer.cornerRadius = 12
        rootFlexContainer.layer.borderWidth = 0.75
        rootFlexContainer.layer.borderColor = UserInterfaceTheme.current.gray.highlight.cgColor
        
        let getButtonHeight: CGFloat = adaptiveLayout.getSize(forLarge: 60, forBig: 52, defaultSize: 48)
        
        textHolder.flex
            .alignItems(.center)
            .justifyContent(.center)
            .padding(0, 20, 0, 20)
            .define{ flex in
                flex.addItem(title).marginBottom(8)
                flex.addItem(descriptionText)
        }
        
        contentHolder.flex
            .alignItems(.center)
            .justifyContent(.start)
            .define { flex in
                flex.addItem(imageView)
                flex.addItem(textHolder)
        }
        
        rootFlexContainer.flex
            .alignItems(.center).justifyContent(.start).shrink(1)
            .height(adaptiveLayout.getSize(forLarge: 360, forBig: 318, defaultSize: 270))
            .marginBottom(25)
            .define { flex in
                flex.addItem(contentHolder)
                
                flex.addItem(separatorView)
                    .position(.absolute).bottom(getButtonHeight)
                    .width(100%).height(1)
                    .backgroundColor(UserInterfaceTheme.current.gray.dim)
                flex.addItem(button)
                    .backgroundColor(UserInterfaceTheme.current.background)
                    .position(.absolute).bottom(0)
                    .alignItems(.center).justifyContent(.center)
                    .width(100%).height(getButtonHeight)
                    .define({ wrapperFlex in wrapperFlex.addItem(buttonText) })
        }
    }
}
