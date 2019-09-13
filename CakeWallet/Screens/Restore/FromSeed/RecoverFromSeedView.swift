import UIKit
import FlexLayout


final class RecoverFromSeedView: BaseFlexView {
    let cardWrapper, actionButtonsContainer, seedContainer: UIView
    let restoreFromHeightView: RestoreFromHeightView
    var walletNameField: CWTextField
    var seedField: CWTextField
    let doneButton: LoadingButton
    
    required init() {
        cardWrapper = UIView()
        actionButtonsContainer = UIView()
        seedContainer = UIView()
        walletNameField = CWTextField(placeholder: NSLocalizedString("wallet_name", comment: ""), fontSize: 16)
        restoreFromHeightView = RestoreFromHeightView()
        seedField = CWTextField(placeholder: NSLocalizedString("seed", comment: ""), fontSize: 16)
        doneButton = LoadingButton()
        doneButton.setTitle(NSLocalizedString("recover", comment: ""), for: .normal)
        
        super.init()
    }
    
    override func configureView() {
        super.configureView()
        cardWrapper.layer.cornerRadius = 12
        cardWrapper.backgroundColor = UserInterfaceTheme.current.background
        seedField.textColor = UserInterfaceTheme.current.textVariants.main
        seedField.backgroundColor = UserInterfaceTheme.current.background
        walletNameField.textColor = UserInterfaceTheme.current.textVariants.main
        if let placeholder = seedField.placeholder {
            seedField.attributedPlaceholder = NSAttributedString(string:placeholder, attributes: [NSAttributedStringKey.foregroundColor: UserInterfaceTheme.current.textVariants.dim])
        }
    }
    
    override func configureConstraints() {

        seedContainer.flex
            .define { flex in
                flex.addItem(seedField).width(100%).paddingRight(30)
        }
        
        cardWrapper.flex
            .justifyContent(.start)
            .alignItems(.center)
            .padding(40, 10, 45, 10)
            .define{ flex in
                flex.addItem(walletNameField).width(100%).marginBottom(40)
                flex.addItem(restoreFromHeightView).width(100%).marginBottom(40)
                flex.addItem(seedContainer).width(100%)
        }
        
        actionButtonsContainer.flex
            .justifyContent(.center)
            .alignItems(.center)
            .define { flex in
                flex.addItem(doneButton).height(56).width(100%)
        }
        
        rootFlexContainer.flex
            .justifyContent(.spaceBetween)
            .alignItems(.center)
            .padding(20)
            .define { flex in
                flex.addItem(cardWrapper).width(100%)
                flex.addItem(actionButtonsContainer).width(100%)
        }
    }
}
