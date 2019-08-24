import UIKit
import FlexLayout

final class RecoverCardView: BaseFlexView {
    var walletNameField, restoreHeightField, restoreDateField: CWTextField
    var seedView: AddressView
    
    required init() {
        walletNameField = CWTextField(placeholder: NSLocalizedString("wallet_name", comment: ""), fontSize: 16)
        restoreHeightField = CWTextField(fontSize: 16)
        restoreDateField = CWTextField(fontSize: 16)
        seedView = AddressView(placeholder: "")
        seedView.availablePickers = []
        super.init()
    }
    
    override func configureConstraints() {
        rootFlexContainer.layer.cornerRadius = 12
        rootFlexContainer.layer.applySketchShadow(color: UIColor(hex: 0x29174d), alpha: 0.1, x: 0, y: 0, blur: 20, spread: -10)
        rootFlexContainer.backgroundColor = Theme.current.card.background
        
        rootFlexContainer.flex
            .justifyContent(.start)
            .alignItems(.center)
            .padding(30, 20, 40, 20)
            .define{ flex in
                flex.addItem(walletNameField).width(100%).marginBottom(25)
                flex.addItem(restoreHeightField).width(100%).marginBottom(25)
                flex.addItem(restoreDateField).width(100%).marginBottom(25)
                flex.addItem(seedView).width(100%)
        }
    }
}
