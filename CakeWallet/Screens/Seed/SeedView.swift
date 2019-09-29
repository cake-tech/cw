import UIKit
import FlexLayout

final class SeedView: BaseFlexView {
    let imageView: UIImageView
    let cardView: UIView
    let dateLabel: UILabel
    let seedLabel: UILabel
    let saveButton: UIButton
    let copyButton: UIButton
    let buttonsRowContainer: UIView

    let titleLabel: UILabel
    let separatorView: UIView
    
    required init() {
        cardView = UIView()
        imageView = UIImageView(image: UserInterfaceTheme.current.asset(named: "create_wallet_logo"))
        dateLabel = UILabel(fontSize: 16)
        seedLabel = UILabel(fontSize: 14)
        saveButton = SecondaryButton(title: NSLocalizedString("save", comment: ""))
        saveButton.layer.borderColor = UserInterfaceTheme.current.purple.main.cgColor
        saveButton.layer.backgroundColor = UserInterfaceTheme.current.purple.dim.cgColor
        
        copyButton = PrimaryButton(title: NSLocalizedString("copy", comment: ""))
        copyButton.layer.borderColor = UserInterfaceTheme.current.blue.main.cgColor
        copyButton.layer.backgroundColor = UserInterfaceTheme.current.blue.dim.cgColor
        
        buttonsRowContainer = UIView()
        titleLabel = UILabel()
        titleLabel.font = UIFont(name: "Lato-Semibold", size: 18)
        
        separatorView = UIView()
        super.init()
    }
    
    override func configureView() {
        super.configureView()
        dateLabel.textAlignment = .center
        seedLabel.textAlignment = .center
        seedLabel.numberOfLines = 0
        titleLabel.textAlignment = .center
        titleLabel.textColor = UserInterfaceTheme.current.text
        imageView.contentMode = .scaleAspectFit;
    }
    
    override func configureConstraints() {
        cardView.flex.alignItems(.center).padding(20).define { flex in
            flex.addItem(imageView).size(CGSize(width: 190, height: 115.9)).marginBottom(25)
            flex.addItem(titleLabel).height(35).width(100%).marginBottom(10)
            flex.addItem(separatorView)
                .height(1).width(100%)
                .margin(UIEdgeInsets(top: 0, left: -20, bottom: 0, right: -20))
                .backgroundColor(UserInterfaceTheme.current.gray.dim)
            flex.addItem(dateLabel).width(100%)
            flex.addItem(seedLabel).width(100%).margin(UIEdgeInsets(top: 20, left: 0, bottom: 20, right: 0))
        }
        
        buttonsRowContainer.flex.direction(.row).justifyContent(.spaceBetween).define { flex in
            flex.addItem(saveButton).height(56).width(45%)
            flex.addItem(copyButton).height(56).width(45%)
        }

        rootFlexContainer.flex.alignItems(.center).define { flex in
            flex.addItem(cardView).width(80%)
            flex.addItem(buttonsRowContainer).width(80%).marginTop(20)
        }
    }
}
