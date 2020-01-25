import UIKit
import FlexLayout

final class PickerButtonView: BaseFlexView {
    let pickedCurrency, walletNameLabel: UILabel
    let pickerIcon: UIImageView
    
    required init() {
        pickerIcon = UIImageView(image: UIImage(named: "arrow_bottom_purple_icon"))
        pickedCurrency = UILabel(text: "")
        walletNameLabel = UILabel(text: "")
        
        super.init()
    }
    
    override func configureView() {
        super.configureView()
        
        pickedCurrency.font = applyFont(ofSize: 26, weight: .bold)
        walletNameLabel.font = applyFont(ofSize: 13)
        walletNameLabel.textColor = UserInterfaceTheme.current.textVariants.highlight
        backgroundColor = .clear
    }
    
    override func configureConstraints() {
        let currencyWithArrowHolder = UIView()
        
        currencyWithArrowHolder.flex
            .direction(.row)
            .alignItems(.center)
            .define{ flex in
                flex.addItem(pickedCurrency).width(80)
                flex.addItem(pickerIcon)
        }
        
        rootFlexContainer.flex
            .backgroundColor(.clear)
            .define{ flex in
                flex.addItem(currencyWithArrowHolder)
                flex.addItem(walletNameLabel).height(20).width(100%)
        }
    }
}

final class ExchangeCardView: BaseFlexView {
    let cardType: ExchangeCardType
    let cardTitle: UILabel
    let topCardView: UIView
    let pickerRow: UIView
    let pickerButton: UIView
    let amountTextField: CWTextField
    let addressContainer: AddressView
    let receiveView: UIView
    let receiveViewTitle: UILabel
    let receiveViewAmount: UILabel
    let pickerButtonView: PickerButtonView
    let limitsRow: UIView
    let maxLabel: UILabel
    let minLabel: UILabel
    let addressFieldRow:UIView = UIView()
    let estimatedField: UILabel
    
    var wantsEstimatedField:Bool = false {
        didSet {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else {
                    return
                }
                
                let field = (self.cardType == .deposit ? self.amountTextField : self.receiveView)
                
                self.estimatedField.isHidden = !self.wantsEstimatedField
                
                if !self.wantsEstimatedField {
                    field.flex.minWidth(100%)
                    field.flex.left(0)
                    self.estimatedField.flex.width(0)
                } else {
                    field.flex.minWidth(50%)
                    field.flex.grow(1)
                    self.estimatedField.flex.grow(1)
                }
                
                self.addressFieldRow.flex.layout()
            }
        }
    }
    
    required init(cardType: ExchangeCardType, cardTitle: String, addressPlaceholder: String) {
        self.cardType = cardType
        self.cardTitle = UILabel(text: cardTitle)
        topCardView = UIView()
        pickerRow = UIView()
        pickerButton = UIView()
        amountTextField = CWTextField(placeholder: "0.000", fontSize: 25)
        addressContainer = AddressView(placeholder: addressPlaceholder)
        receiveView = UIView()
        receiveViewTitle = UILabel(text: "You will receive")
        receiveViewAmount = UILabel(text: "")
        pickerButtonView = PickerButtonView()
        limitsRow = UIView()
        maxLabel = UILabel(fontSize: 10)
        minLabel = UILabel(fontSize: 10)
        estimatedField = UILabel(fontSize:12)
        super.init()
    }
    
    required init() {
        fatalError("init() has not been implemented")
    }
    
    override func configureView() {
        super.configureView()
        cardTitle.font = applyFont(ofSize: 17, weight: .semibold)
        amountTextField.textAlignment = .right
        amountTextField.keyboardType = .decimalPad
        receiveViewTitle.font = applyFont(ofSize: 15)
        receiveViewTitle.textColor = UserInterfaceTheme.current.textVariants.highlight
        receiveViewTitle.textAlignment = .right
        receiveViewAmount.font = applyFont(ofSize: 22, weight: .semibold)
        receiveViewAmount.textColor = UserInterfaceTheme.current.purple.main
        receiveViewAmount.textAlignment = .right
        maxLabel.textColor = UserInterfaceTheme.current.textVariants.main
        maxLabel.textAlignment = .right
        minLabel.textColor = UserInterfaceTheme.current.textVariants.main
        minLabel.textAlignment = .right
        backgroundColor = .clear
        rootFlexContainer.layer.cornerRadius = 12
    
        estimatedField.layer.backgroundColor = UserInterfaceTheme.current.gray.dim.cgColor
        estimatedField.textColor = UserInterfaceTheme.current.gray.highlight
        estimatedField.layer.cornerRadius = 10
        estimatedField.text = "Estimated"
        estimatedField.textAlignment = .center
    }
    
    override func configureConstraints() {
        limitsRow.flex.direction(.row).define { flex in
            flex.addItem(minLabel).width(50%)
            flex.addItem(maxLabel).width(50%)
        }
        
        receiveView.flex
            .alignItems(.end)
            .define{ flex in
                flex.addItem(receiveViewTitle)
                flex.addItem(receiveViewAmount).width(100%)
        }
        
        topCardView.flex
            .direction(.row)
            .justifyContent(.spaceBetween)
            .alignItems(.end)
            .width(100%)
            .define{ flex in
                flex.addItem(pickerButtonView)
                flex.addItem(UIView())
                    .width(67%)
                    .paddingBottom(7)
                    .define({ flex in
                        flex.addItem(addressFieldRow).direction(.row).define({ flex in
                            flex.addItem(estimatedField).height(32).padding(10).alignSelf(.center).width(10%).grow(1)
                            flex.addItem(cardType == .deposit ? amountTextField : receiveView).grow(1)
                        }).alignContent(.center).justifyContent(.center)
                        flex.addItem(limitsRow).height(20).width(100%)
                })
        }
        
        rootFlexContainer.flex
            .justifyContent(.start)
            .alignItems(.center)
            .padding(18, 15, 35, 15)
            .backgroundColor(UserInterfaceTheme.current.cardColor)
            .define{ flex in
                flex.addItem(cardTitle).marginBottom(25)
                flex.addItem(topCardView).marginBottom(25)
                flex.addItem(addressContainer).width(100%)
        }
    }
}
