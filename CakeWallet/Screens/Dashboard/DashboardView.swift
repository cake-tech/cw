import UIKit
import PinLayout
import FlexLayout

enum DashboardActionType {
    case send, receive
    
    var title: String {
        switch self {
        case .send:
            return NSLocalizedString("send", comment: "")
        case .receive:
            return NSLocalizedString("receive", comment: "")
        }
    }
    
    var image: UIImage {
        switch self {
        case .send:
            return UIImage(named: "send_button_icon")!
        case .receive:
            return UIImage(named: "receive_button_icon")!
        }
    }
    
    var borderColor: UIColor {
        switch self {
        case .send:
            return UserInterfaceTheme.current.purple.highlight
        case .receive:
            return UserInterfaceTheme.current.blue.highlight
        }
    }
    
    var backgroundColor: UIColor {
        switch self {
        case .send:
            return UserInterfaceTheme.current.purple.dim
        case .receive:
            return UserInterfaceTheme.current.blue.dim
        }
    }
}

final class DashboardActionButton: BaseFlexView {
    let type: DashboardActionType
    let wrapper: UIView
    let label: UILabel
    let buttonImageView: UIImageView
    
    required init(type: DashboardActionType) {
        self.type = type
        wrapper = UIView()
        label = UILabel(text: type.title)
        buttonImageView = UIImageView()
        
        super.init()
    }
    
    required init() {
        self.type = .send
        wrapper = UIView()
        label = UILabel()
        buttonImageView = UIImageView()
        
        super.init()
    }
    
    override func configureView() {
        super.configureView()
        label.font = applyFont(ofSize: 16)
        
        wrapper.applyCardSketchShadow()
        wrapper.frame = CGRect(x: 0, y: 0, width: 200, height: 60)
        buttonImageView.image = type.image
        
        rootFlexContainer.layer.cornerRadius = 12
        wrapper.layer.cornerRadius = 12
        wrapper.layer.borderWidth = 1
        wrapper.layer.borderColor = type.borderColor.cgColor
        backgroundColor = .clear
    }
    
    override func configureConstraints() {
        wrapper.flex
            .justifyContent(.center)
            .alignItems(.center)
            .backgroundColor(type.backgroundColor)
            .define{ flex in
                flex.addItem(buttonImageView).position(.absolute).top(17).left(15)
                flex.addItem(label).marginLeft(12)
        }
        
        rootFlexContainer.flex
            .backgroundColor(.clear)
            .define { flex in
                flex.addItem(wrapper).width(100%).height(100%)
        }
    }
    
    func themeChanged() {
        wrapper.layer.borderColor = type.borderColor.cgColor
        wrapper.flex.backgroundColor(type.backgroundColor).markDirty()
    }
}

final class DashboardView: BaseScrollFlexView {
    static let tableSectionHeaderHeight = 45 as CGFloat
    static let fixedHeaderTopOffset = 45 as CGFloat
    static let headerButtonsHeight = 60 as CGFloat
    static let minHeaderButtonsHeight = 45 as CGFloat
    static let headerMinHeight: CGFloat = 215
    static let fixedHeaderHeight = 330 as CGFloat
    public var lastDoneDate:Date
    
    let fixedHeader: UIView
    let fiatAmountLabel, cryptoAmountLabel, cryptoTitleLabel, transactionTitleLabel, blockUnlockLabel: UILabel
    let progressBar: ProgressBar
    let buttonsRow: UIView
    let receiveButton, sendButton: DashboardActionButton
    let transactionsTableView: UITableView
    let cardViewCoreDataWrapper: UIView
    let buttonsRowPadding: CGFloat
    
    required init() {
        fixedHeader = UIView()
        progressBar = ProgressBar()
        cryptoAmountLabel = UILabel()
        fiatAmountLabel = UILabel.withLightText(fontSize: 17)
        cryptoTitleLabel = UILabel(fontSize: 16)
        blockUnlockLabel = UILabel(fontSize: 13)
        receiveButton = DashboardActionButton(type: .receive)
        sendButton = DashboardActionButton(type: .send)
        buttonsRow = UIView()
        transactionTitleLabel = UILabel.withLightText(fontSize: 16)
        transactionsTableView = UITableView.init(frame: CGRect.zero, style: .grouped)
        cardViewCoreDataWrapper = UIView()
        buttonsRowPadding = 10
        lastDoneDate = Date()
        super.init()
    }
    
    override func configureView() {
        super.configureView()
        
        scrollView.showsVerticalScrollIndicator = false
        cryptoAmountLabel.font = applyFont(ofSize: 40)
        cryptoAmountLabel.textAlignment = .center
        cryptoAmountLabel.textColor = UserInterfaceTheme.current.text
        fiatAmountLabel.textColor = UserInterfaceTheme.current.textVariants.main
        fiatAmountLabel.textAlignment = .center
        fiatAmountLabel.font = applyFont(ofSize: 17)
        cryptoTitleLabel.font = applyFont(ofSize: 16, weight: .semibold)

        transactionsTableView.separatorStyle = .none
        cryptoTitleLabel.textAlignment = .center
        blockUnlockLabel.textAlignment = .center
        blockUnlockLabel.textColor = UserInterfaceTheme.current.red.main
        
        transactionsTableView.tableFooterView = UIView()
        transactionsTableView.isScrollEnabled = false
        transactionsTableView.layoutMargins = .zero
        transactionsTableView.separatorInset = .zero
        transactionsTableView.backgroundColor = UserInterfaceTheme.current.background
        
        transactionTitleLabel.text = NSLocalizedString("transactions", comment: "")
        transactionTitleLabel.textAlignment = .center
        transactionsTableView.layer.masksToBounds = false
        rootFlexContainer.layer.masksToBounds = true
        backgroundColor = UserInterfaceTheme.current.background
        
        fixedHeader.applyCardSketchShadow()
        addSubview(fixedHeader)
        bringSubview(toFront: fixedHeader)
    }
    
    override func configureConstraints() {
        super.configureConstraints()
        
        cardViewCoreDataWrapper.flex
            .alignItems(.center)
            .width(100%)
            .define{ flex in
                flex.addItem(cryptoTitleLabel).width(100%).height(20).marginBottom(10)
                flex.addItem(cryptoAmountLabel).alignSelf(.center).marginBottom(10)
                flex.addItem(fiatAmountLabel).width(100%).height(20)
                flex.addItem(blockUnlockLabel).width(100%).alignSelf(.center).marginTop(7)
        }
        
        buttonsRow.flex
            .direction(.row).alignItems(.center).justifyContent(.center)
            .paddingHorizontal(buttonsRowPadding)
            .backgroundColor(.clear)
            .define { flex in
                flex.addItem(sendButton).width(47%).height(100%).marginRight(7)
                flex.addItem(receiveButton).width(47%).height(100%).marginLeft(7)
        }
        
        fixedHeader.flex
            .alignItems(.center)
            .justifyContent(.spaceBetween)
            .width(100%)
            .height(DashboardView.fixedHeaderHeight)
            .backgroundColor(UserInterfaceTheme.current.background)
            .paddingBottom(31)
            .define { flex in
                flex.addItem(cardViewCoreDataWrapper).width(100%).marginTop(DashboardView.fixedHeaderTopOffset)
                flex.addItem(progressBar).width(200).height(22).bottom(120).position(.absolute)
                flex.addItem(buttonsRow).height(DashboardView.headerButtonsHeight).marginTop(15)
        }
        
        rootFlexContainer.flex
            .backgroundColor(UserInterfaceTheme.current.background)
            .define { flex in
                flex.addItem(transactionsTableView).width(100%).minWidth(200).grow(1).marginTop(DashboardView.fixedHeaderHeight - 10)
        }
    }
    
    func themeChanged() {
        transactionsTableView.backgroundColor = UserInterfaceTheme.current.background
        fixedHeader.flex.backgroundColor(UserInterfaceTheme.current.background).markDirty()
        rootFlexContainer.flex.backgroundColor(UserInterfaceTheme.current.background).markDirty()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        fixedHeader.pin.top(pin.safeArea.top).left(pin.safeArea.left).right(pin.safeArea.right)
        fixedHeader.flex.layout()
    }
}

