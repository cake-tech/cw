import UIKit
import FlexLayout

final class DisclaimerView: BaseFlexView {
    let imageView = UIImageView()
    let textView: UITextView
    let titleLabel: UILabel
    let bottomView: UIView
    let acceptButton: UIButton
    let checkBoxTitleButton: TransparentButton
    let checkBoxWrapper: UIView
    let checkBox: CheckBox
    let gradientView: UIView
    
    required init() {
        textView = UITextView()
        titleLabel = UILabel()
        bottomView = UIView()
        acceptButton = PrimaryButton(title: NSLocalizedString("accept", comment: ""))
        checkBoxWrapper = UIView()
        checkBoxTitleButton = TransparentButton(title: NSLocalizedString("terms_of_use_agree", comment: ""))
        checkBox = CheckBox()
        gradientView = UIView()
        
        super.init()
    }
    
    override func configureView() {
        super.configureView()
        imageView.image = UIImage.init(named:"AppIcon")?.resized(to: CGSize(width: 35, height: 35))
        titleLabel.font = UIFont(name: "Lato-SemiBold", size: 18)
        titleLabel.textAlignment = .left
        titleLabel.lineBreakMode = .byWordWrapping
        titleLabel.numberOfLines = 0
        titleLabel.textColor = UserInterfaceTheme.current.text
        titleLabel.text = NSLocalizedString("terms", comment: "")
        textView.font = applyFont(ofSize: 14)
        textView.isEditable = false

        checkBoxTitleButton.setTitleColor(UserInterfaceTheme.current.text, for: .normal)
        checkBoxTitleButton.titleLabel?.font = applyFont(ofSize: 13, weight: .semibold)
        textView.backgroundColor = .clear
        
        var newFrame = gradientView.frame
        newFrame.size.width = UIScreen.main.bounds.size.width
        newFrame.size.height = 40
        
        gradientView.frame = newFrame
        
        let mask = CAGradientLayer()
        mask.startPoint = CGPoint(x: 0.0, y: 0.0)
        mask.endPoint = CGPoint(x: 0.0, y: 3.0)
        let whiteColor = UserInterfaceTheme.current.cardColor
        
        mask.colors = [
            whiteColor.withAlphaComponent(0.0).cgColor,
            whiteColor.withAlphaComponent(1.0).cgColor,
            whiteColor.withAlphaComponent(1.0).cgColor
        ]
        mask.locations = [NSNumber(value: 0.0),NSNumber(value: 0.2),NSNumber(value: 1.0)]
        mask.frame = gradientView.bounds
        gradientView.layer.mask = mask
    }
    
    override func configureConstraints() {
        checkBoxWrapper.flex.direction(.row).alignItems(.center).marginBottom(10).define{ flex in
            flex.addItem(checkBox)
            flex.addItem(checkBoxTitleButton)
        }
        
        bottomView.flex.define { flex in
            flex.addItem(gradientView).position(.absolute).top(-35).backgroundColor(UserInterfaceTheme.current.cardColor)
            flex.addItem(checkBoxWrapper).marginLeft(25)
            flex.addItem(acceptButton).height(56).width(100%)
        }
        let leftAlignedView = UIView()
        leftAlignedView.flex.direction(.column).alignContent(.start).define { flex in
            flex.addItem(imageView).width(35).height(35)
            flex.addItem(titleLabel).position(.relative).marginTop(10).width(200)
        }
    
        rootFlexContainer.flex.alignItems(.center).padding(0, 15, 0, 15).define{ flex in
            flex.addItem(leftAlignedView).width(100%).marginTop(15).marginBottom(10)
            flex.addItem(textView).marginBottom(10).marginBottom(100)
            flex.addItem(bottomView).height(130).position(.absolute).bottom(0).width(100%).backgroundColor(UserInterfaceTheme.current.cardColor)
        }
    }
}
