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
    var hasCheckbox:Bool
    
    init(withCheckbox:Bool = true) {
        textView = UITextView()
        titleLabel = UILabel()
        bottomView = UIView()
        acceptButton = PrimaryButton(title: NSLocalizedString("accept", comment: ""))
        checkBoxWrapper = UIView()
        checkBoxTitleButton = TransparentButton(title: NSLocalizedString("terms_of_use_agree", comment: ""))
        checkBox = CheckBox()
        gradientView = UIView()
        hasCheckbox = withCheckbox
        super.init()
    }
    
    required convenience init() {
        self.init(withCheckbox:true)
    }

//    override var safeAreaInsets: UIEdgeInsets {
//        get {
//            let superSafe = super.safeAreaInsets
//            return UIEdgeInsets(top: superSafe.top, left: superSafe.left, bottom: 0, right: superSafe.right)
//        }
//    }
    
    override func configureView() {
        super.configureView()
        imageView.image = UIImage.init(named:"cake_logo_image")?.resized(to: CGSize(width: 35, height: 35))
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
        checkBoxWrapper.flex.direction(.row).alignItems(.center).marginBottom(20).define{ flex in
            flex.addItem(checkBox)
            flex.addItem(checkBoxTitleButton)
        }
        
        bottomView.flex.define { flex in
            flex.addItem(gradientView).position(.absolute).top(-35).backgroundColor(UserInterfaceTheme.current.cardColor)

                flex.addItem(checkBoxWrapper).marginLeft(25)
                flex.addItem(acceptButton).height(56).width(90%).alignSelf(.center)


        }
        
        let leftAlignedView = UIView()
        leftAlignedView.flex.direction(.column).alignContent(.start).define { flex in
            flex.addItem(imageView).width(35).height(35)
            flex.addItem(titleLabel).marginTop(10).width(200)
        }
    
        rootFlexContainer.flex.alignItems(.center).define{ flex in
            flex.addItem(leftAlignedView).width(100%).paddingHorizontal(15)
            
            if (hasCheckbox) {
                flex.addItem(textView).marginHorizontal(15)
                flex.addItem(bottomView).position(.absolute).bottom(0).width(100%).backgroundColor(UserInterfaceTheme.current.cardColor).paddingBottom(45)
            } else {
                flex.addItem(textView).marginBottom(15).marginHorizontal(15)
            }
        }
    }
}
