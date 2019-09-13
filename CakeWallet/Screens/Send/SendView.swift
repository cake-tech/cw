import UIKit
import FlexLayout

final class SendView: BaseScrollFlexViewWithBottomSection {
    let mainContentHolder: UIView
    let walletNameContainer: UIView
    let addressView: AddressView
    let takeFromAddressBookButton: Button
    let paymentIdTextField: CWTextField
    let paymentIdContainer: UIView
    let cryptoAmountTextField: CWTextField
    let fiatAmountTextField: CWTextField
    let currenciesRowViev: UIView
    let currenciesContainer: UIView
    let estimatedFeeTitleLabel: UILabel
    let estimatedFeeValueLabel: UILabel
    let estimatedFeeContriner: UIView
    let estimatedDescriptionLabel: UILabel
    let sendButton: LoadingButton
    let walletContainer: UIView
    let walletTitleLabel, walletNameLabel: UILabel
    let cryptoAmountValueLabel: UILabel
    let cryptoAmountTitleLabel: UILabel
    let sendAllButton: TransparentButton
    let cryptoAmonutContainer: UIView
    let scanQrForPaymentId: UIButton
    let fiatAmountTextFieldLeftView: UILabel
    
    required init() {
        mainContentHolder = UIView()
        walletNameContainer = UIView()
        addressView = AddressView(placeholder: "Monero address")
        takeFromAddressBookButton = SecondaryButton(title: NSLocalizedString("A", comment: ""))
        paymentIdTextField = CWTextField(placeholder: "Payment ID (optional)", fontSize: 15)
        paymentIdContainer = UIView()
        cryptoAmountTextField = CWTextField(placeholder: "0.0000")
        fiatAmountTextField = CWTextField(placeholder: "0.0000")
        currenciesRowViev = UIView()
        currenciesContainer = UIView()
        estimatedFeeTitleLabel = UILabel(fontSize: 12)
        estimatedFeeValueLabel = UILabel(fontSize: 12)
        estimatedFeeContriner = UIView()
        estimatedDescriptionLabel = UILabel.withLightText(fontSize: 12)
        sendButton = LoadingButton()
        walletContainer = UIView()
        walletTitleLabel = UILabel(text: NSLocalizedString("your_wallet", comment: ""))
        walletNameLabel = UILabel()
        cryptoAmountValueLabel = UILabel()
        cryptoAmountTitleLabel = UILabel()
        sendAllButton = TransparentButton(title: NSLocalizedString("all", comment: ""))
        cryptoAmonutContainer = UIView()
        scanQrForPaymentId = UIButton()
        fiatAmountTextFieldLeftView = UILabel(text: "USD:")
        super.init()
    }
    
    override func configureView() {
        super.configureView()
        
        backgroundColor = UserInterfaceTheme.current.background

        walletNameLabel.font = applyFont()
        estimatedFeeValueLabel.numberOfLines = 0
        estimatedFeeValueLabel.textAlignment = .right

        cryptoAmountTitleLabel.font = applyFont(ofSize: 14)
        cryptoAmountTitleLabel.textAlignment = .right
        
        walletTitleLabel.font = applyFont(ofSize: 14)
        walletTitleLabel.textColor = UserInterfaceTheme.current.purple.highlight
        
        walletNameLabel.textColor = UserInterfaceTheme.current.textVariants.highlight
        
        cryptoAmountValueLabel.textAlignment = .right
        cryptoAmountValueLabel.font = applyFont(ofSize: 26)
        cryptoAmountValueLabel.textColor = UserInterfaceTheme.current.textVariants.highlight
        cryptoAmountTitleLabel.textColor = UserInterfaceTheme.current.text
        cryptoAmountTextField.keyboardType = .decimalPad
        
        let cryptoAmountTextFieldLeftView = UILabel(text: "XMR:")
        cryptoAmountTextFieldLeftView.font = applyFont()
        cryptoAmountTextFieldLeftView.frame = CGRect(x: 0, y: 0, width: 50, height: 50)
        cryptoAmountTextFieldLeftView.textColor = UserInterfaceTheme.current.textVariants.dim
        let cryptoAmountTextFieldRightView = UIView()
        cryptoAmountTextFieldRightView.frame = CGRect(x: 0, y: 0, width: 50, height: 50)
        
        cryptoAmountTextField.leftView = cryptoAmountTextFieldLeftView
        cryptoAmountTextField.leftViewMode = .always
        cryptoAmountTextField.textColor = UserInterfaceTheme.current.text
        
        cryptoAmountTextField.rightView = cryptoAmountTextFieldRightView
        cryptoAmountTextField.rightViewMode = .always
        
       
        fiatAmountTextFieldLeftView.font = applyFont()
        fiatAmountTextFieldLeftView.frame = CGRect(x: 0, y: 0, width: 50, height: 50)
        fiatAmountTextFieldLeftView.textColor = UserInterfaceTheme.current.textVariants.dim
        
        fiatAmountTextField.keyboardType = .decimalPad
        fiatAmountTextField.leftView = fiatAmountTextFieldLeftView
        fiatAmountTextField.leftViewMode = .always
        fiatAmountTextField.textColor = UserInterfaceTheme.current.text
        
        sendAllButton.setTitleColor(UserInterfaceTheme.current.textVariants.main, for: .normal)
        sendAllButton.titleLabel?.font = applyFont(ofSize: 11)

        sendButton.setTitle(NSLocalizedString("send", comment: ""), for: .normal)
        scanQrForPaymentId.setImage(UIImage(named: "qr_code_icon"), for: .normal)
        scanQrForPaymentId.imageEdgeInsets = UIEdgeInsetsMake(5, 5, 5, 5)
        scanQrForPaymentId.layer.cornerRadius = 5
        scanQrForPaymentId.layer.backgroundColor = UserInterfaceTheme.current.gray.dim.cgColor
        
        scanQrForPaymentId.tintColor = UserInterfaceTheme.current.gray.highlight
        
        paymentIdTextField.rightView = UIView(frame: CGRect(x: 0, y: 0, width: 35, height: 35))
        paymentIdTextField.rightViewMode = .always
        paymentIdTextField.textColor = UserInterfaceTheme.current.text
    }
    
    override func configureConstraints() {
        walletNameContainer.flex.define { flex in
            flex.addItem(walletTitleLabel).marginBottom(5)
            flex.addItem(walletNameLabel)
        }
        
        cryptoAmonutContainer.flex.define { flex in
            flex.addItem(cryptoAmountTitleLabel)
            flex.addItem(cryptoAmountValueLabel)
        }
        
        walletContainer.flex
            .direction(.row).justifyContent(.spaceBetween)
            .width(100%)
            .paddingTop(20)
            .paddingBottom(15)
            .backgroundColor(UserInterfaceTheme.current.sendCardColor).alignContent(.center)
            .define { flex in
                flex.addItem(UIView()).width(100%).height(1).backgroundColor(UserInterfaceTheme.current.gray.dim).position(.absolute).top(0).left(0)
                flex.addItem(walletNameContainer).marginHorizontal(20)
                flex.addItem(cryptoAmonutContainer).marginHorizontal(20)
                flex.addItem(UIView()).width(100%).height(1).backgroundColor(UserInterfaceTheme.current.gray.dim).position(.absolute).bottom(0).left(0)
        }
        
        currenciesContainer.flex
            .justifyContent(.spaceBetween)
            .define { flex in
                flex.addItem(cryptoAmountTextField).width(100%).marginBottom(25)
                flex.addItem(fiatAmountTextField).width(100%)
                flex.addItem(sendAllButton).height(40).marginLeft(10).position(.absolute).right(-5).top(-5)
        }
        
        estimatedFeeContriner.flex.direction(.row).justifyContent(.spaceBetween).alignItems(.start).define { flex in
            flex.addItem(estimatedFeeTitleLabel)
            flex.addItem(estimatedFeeValueLabel)
        }
        
        paymentIdContainer.flex.define { flex in
            flex.addItem(paymentIdTextField).width(100%)
            flex.addItem(scanQrForPaymentId).width(35).height(35).position(.absolute).right(0).bottom(5)
        }
        
        mainContentHolder.flex
            .alignItems(.center)
            .padding(30)
            .backgroundColor(UserInterfaceTheme.current.background)
            .define { flex in
                flex.addItem(addressView).width(100%)
                flex.addItem(paymentIdContainer).width(100%).marginTop(30)
            
                flex.addItem(currenciesContainer).marginTop(25).width(100%)
            
                flex.addItem(estimatedFeeContriner).marginTop(20).width(100%)
                flex.addItem(estimatedDescriptionLabel).marginTop(20).width(100%)
        }
        
        rootFlexContainer.flex.backgroundColor(UserInterfaceTheme.current.background).define { flex in
            flex.addItem(walletContainer)
            flex.addItem(mainContentHolder).marginTop(20)
        }
        
        bottomSectionView.flex.backgroundColor(UserInterfaceTheme.current.background).padding(20).define { flex in
            flex.addItem(sendButton).height(56)
        }
    }
}
