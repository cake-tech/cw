import Foundation
import UIKit
import FlexLayout

final class SendConfirmView: BaseFlexView {
    let imageView = UIImageView()
    
    let confirmSendingTitle = UILabel()
    let amountLabel = UILabel()
    let feeLabel = UILabel()
    
    let recipientAddressTitle = UILabel()
    let addressLabel = UILabel()
    
    let sendButton = PrimaryButton(title: NSLocalizedString("send", comment: ""))
    let cancelButton = SecondaryButton(title: NSLocalizedString("cancel", comment: ""))
    
    required init() {
        super.init()
    }
    
    override func configureView() {
        super.configureView()
        backgroundColor = UserInterfaceTheme.current.background
        
        imageView.image = UIImage(named:"send_image")
        imageView.contentMode = .scaleAspectFit
        
        confirmSendingTitle.font = UIFont(name: "Lato-Semibold", size: 20)
        confirmSendingTitle.textColor = UserInterfaceTheme.current.purple.highlight
        
        amountLabel.font = UIFont(name: "Lato-Semibold", size: 32)
        amountLabel.textColor = UserInterfaceTheme.current.textVariants.highlight
        
        feeLabel.font = UIFont(name: "Lato-Semibold", size: 16)
        feeLabel.textColor = UserInterfaceTheme.current.textVariants.dim
        
        recipientAddressTitle.font = UIFont(name: "Lato-SemiBold", size: 14)
        recipientAddressTitle.textColor = UserInterfaceTheme.current.textVariants.main
        
    }
    
    override func configureConstraints() {
        let bottomView = UIView()
        bottomView.flex.marginHorizontal(10).define { flex in
            flex.addItem(cancelButton).height(56).width(40%)
            flex.addItem(sendButton).height(56).width(60%)
        }
        
        let mainView = UIView()
        mainView.flex.alignItems(.center).justifyContent(.center).define { flex in
            flex.addItem(imageView)
            flex.addItem(confirmSendingTitle)
            flex.addItem(amountLabel)
            flex.addItem(feeLabel)
            flex.addItem(recipientAddressTitle)
        }
        
        rootFlexContainer.flex.alignItems(.center).justifyContent(.center).define{ flex in
            flex.addItem(mainView).justifyContent(.center).position(.relative).height(150)
            flex.addItem(bottomView).height(130).position(.absolute).bottom(0).width(100%).backgroundColor(UserInterfaceTheme.current.background)
        }
    }
}
