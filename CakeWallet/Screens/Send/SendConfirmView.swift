import Foundation
import UIKit
import FlexLayout

final class SendConfirmView: BaseFlexView {
    let imageView = UIImageView()
    
    let titleLabel = UILabel()
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
        titleLabel.font = UIFont(name: "Lato-Regular", size: 18)
        backgroundColor = UserInterfaceTheme.current.background
        
        titleLabel.text = NSLocalizedString("confirm_sending", comment: "")
        titleLabel.isUserInteractionEnabled = false
        
        imageView.image = UIImage(named:"send_image")
        imageView.contentMode = .scaleAspectFit
        
        confirmSendingTitle.font = UIFont(name: "Lato-Semibold", size: 20)
        confirmSendingTitle.textColor = UserInterfaceTheme.current.purple.highlight
        confirmSendingTitle.text = NSLocalizedString("confirm_sending", comment: "")
        
        amountLabel.font = UIFont(name: "Lato-Semibold", size: 32)
        amountLabel.textColor = UserInterfaceTheme.current.textVariants.highlight
        
        feeLabel.font = UIFont(name: "Lato-Semibold", size: 16)
        feeLabel.textColor = UserInterfaceTheme.current.textVariants.highlight
        
        recipientAddressTitle.font = UIFont(name: "Lato-SemiBold", size: 14)
        recipientAddressTitle.textColor = UserInterfaceTheme.current.purple.highlight
        recipientAddressTitle.text = NSLocalizedString("recipient_address", comment: "")
        
        addressLabel.font = UIFont(name: "Lato-Semibold", size: 14)
        addressLabel.textColor = UserInterfaceTheme.current.textVariants.highlight
        
        //enable character breaks and multiple lines
        addressLabel.lineBreakMode = .byCharWrapping
        addressLabel.numberOfLines = 0
        addressLabel.textAlignment = .center
        
    }
    
    override func configureConstraints() {
        let bottomView = UIView()
        bottomView.flex.direction(.row).justifyContent(.spaceAround).marginHorizontal(3).define { flex in
            flex.addItem(cancelButton).height(56).width(35%)
            flex.addItem(sendButton).height(56).width(55%)
        }
        
        let mainView = UIView()
        mainView.flex.alignItems(.center).define { flex in
            flex.addItem(titleLabel).marginTop(10).marginBottom(45)
            flex.addItem(imageView).marginTop(58)
            flex.addItem(confirmSendingTitle).marginVertical(3)
            flex.addItem(amountLabel).marginVertical(2)
            flex.addItem(feeLabel).marginBottom(2)
            flex.addItem(UIView()).height(1).width(70%).backgroundColor(UserInterfaceTheme.current.gray.dim).marginVertical(20)
            flex.addItem(recipientAddressTitle).marginVertical(2)
            flex.addItem(addressLabel).marginHorizontal(15%).marginVertical(2)
        }
        
        let rowWrap = UIView()
        rowWrap.flex.direction(.row).justifyContent(.start).define { flex in
            flex.addItem(mainView)
        }
        
        rootFlexContainer.flex.define{ flex in
            flex.addItem(rowWrap).position(.relative)
            flex.addItem(bottomView).height(60).position(.absolute).bottom(0).width(100%).backgroundColor(UserInterfaceTheme.current.background)
        }
    }
}
