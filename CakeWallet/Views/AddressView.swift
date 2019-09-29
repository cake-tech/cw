import UIKit
import FlexLayout
import QRCodeReader

public enum AddressViewPickers:UInt8 {
    static var all:[AddressViewPickers] {
        return [.qrScan, .addressBook, .subaddress]
    }
    case qrScan
    case addressBook
    case subaddress
}

final class AddressView: BaseFlexView {
    
    let textView: AddressTextField
    let borderView, buttonsView: UIView
    let qrScanButton, addressBookButton, subaddressButton: UIButton
    let placeholder: String
    
    private var _pickers:[AddressViewPickers]
    public var availablePickers:[AddressViewPickers] {
        set {
            _pickers = newValue
            layoutButtons()
        }
        get {
            return _pickers
        }
    }

    weak var presenter: UIViewController?
    weak var updateResponsible: QRUriUpdateResponsible?

    private lazy var QRReaderVC: QRCodeReaderViewController = {
        let builder = QRCodeReaderViewControllerBuilder {
            $0.reader = QRCodeReader(metadataObjectTypes: [.qr], captureDevicePosition: .back)
        }
        
        let QRCodeReaderVC = QRCodeReaderViewController(builder: builder)
        QRCodeReaderVC.completionBlock = { [weak self] result in
            guard let this = self else {
                return
            }
            
            if
                let value = result?.value,
                let crypto = this.updateResponsible?.getCrypto(for: this) {
                let uri: QRUri
                
                switch crypto {
                case .bitcoin:
                    uri = BitcoinQRResult(uri: value)
                case .monero:
                    uri = MoneroQRResult(uri: value)
                default:
                    uri = DefaultCryptoQRResult(uri: value, for: crypto)
                }
                
                this.updateAddress(from: uri)
                this.updateResponsible?.updated(this, withURI: uri)
            }
            
            this.QRReaderVC.stopScanning()
            this.QRReaderVC.dismiss(animated: true)
        }
        
        return QRCodeReaderVC
    }()
    
    required init(placeholder: String = "") {
        self.placeholder = placeholder
        textView = AddressTextField()
        borderView = UIView()
        buttonsView = UIView()
        qrScanButton = UIButton()
        addressBookButton = UIButton()
        subaddressButton = UIButton()
        _pickers = AddressViewPickers.all.sorted(by: { return $0.rawValue > $1.rawValue })
        super.init()
    }
    
    required init() {
        self.placeholder = ""
        textView = AddressTextField()
        borderView = UIView()
        buttonsView = UIView()
        qrScanButton = UIButton()
        addressBookButton = UIButton()
        subaddressButton = UIButton()
        _pickers = AddressViewPickers.all
        super.init()
    }
    
    override func configureView() {
        super.configureView()
        
        qrScanButton.imageEdgeInsets = UIEdgeInsetsMake(5, 5, 5, 5)
        qrScanButton.backgroundColor = .clear
        qrScanButton.layer.cornerRadius = 5
        qrScanButton.backgroundColor = UserInterfaceTheme.current.gray.dim
        
        addressBookButton.imageEdgeInsets = UIEdgeInsetsMake(5, 5, 5, 5)
        addressBookButton.backgroundColor = .clear
        addressBookButton.layer.cornerRadius = 5
        addressBookButton.backgroundColor = UserInterfaceTheme.current.gray.dim
        
        subaddressButton.imageEdgeInsets = UIEdgeInsetsMake(5, 5, 5, 5)
        subaddressButton.backgroundColor = .clear
        subaddressButton.layer.cornerRadius = 5
        subaddressButton.backgroundColor = UserInterfaceTheme.current.gray.dim
        
        if let qrScanImage = UIImage(named: "qr_code_icon")?.withRenderingMode(.alwaysTemplate) {
            qrScanButton.setImage(qrScanImage, for: .normal)
            qrScanButton.imageView?.tintColor = UserInterfaceTheme.current.gray.highlight
        }
        
        if let addressBookImage = UIImage(named: "address_book")?.withRenderingMode(.alwaysTemplate) {
            addressBookButton.setImage(addressBookImage, for: .normal)
            addressBookButton.imageView?.tintColor = UserInterfaceTheme.current.gray.highlight
        }
        
        if let subaddressImage = UIImage(named: "receive_icon")?.withRenderingMode(.alwaysTemplate) {
            subaddressButton.setImage(subaddressImage, for: .normal)
            subaddressButton.imageView?.tintColor = UserInterfaceTheme.current.gray.highlight
        }
        
        qrScanButton.addTarget(self, action: #selector(scanQr), for: .touchUpInside)
        addressBookButton.addTarget(self, action: #selector(fromAddressBook), for: .touchUpInside)
        subaddressButton.addTarget(self, action: #selector(fromSubaddress), for: .touchUpInside)
        
        textView.font = applyFont(ofSize: 15, weight: .regular)
        textView.attributedPlaceholder = NSAttributedString(
            string: placeholder,
            attributes: [
                NSAttributedString.Key.foregroundColor: UserInterfaceTheme.current.textVariants.dim,
                NSAttributedStringKey.font: UIFont(name: "Lato-Regular", size: CGFloat(15))!
            ]
        )
        textView.textColor = UserInterfaceTheme.current.text
        textView.rightView = UIView(frame: CGRect(x: 0, y: 0, width: 40*_pickers.count, height: 0))
        textView.rightViewMode = .always
        backgroundColor = .clear
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        textView.change(text: textView.originText.value)
    }
    
    override func configureConstraints() {        
        buttonsView.flex
            .direction(.row).justifyContent(.spaceEvenly).alignItems(.stretch)
            .width(CGFloat(40*availablePickers.count)).paddingLeft(5)
            .define{ flex in
                    flex.addItem(qrScanButton).width(35).height(35)
                    flex.addItem(addressBookButton).width(35).height(35)
                    flex.addItem(subaddressButton).width(35).height(35)
        }
        
        rootFlexContainer.flex
            .width(100%)
            .backgroundColor(.clear)
            .define{ flex in
                flex.addItem(textView).backgroundColor(.clear).width(100%).paddingRight(CGFloat(40*_pickers.count)).marginBottom(11)
                flex.addItem(borderView).height(1).width(100%).backgroundColor(UserInterfaceTheme.current.gray.main)
                flex.addItem(buttonsView).position(.absolute).top(-10).right(0)
        }
    }
    
    private func layoutButtons() {
        textView.rightView = UIView(frame: CGRect(x: 0, y: 0, width: 40*_pickers.count, height: 0))
        textView.flex.paddingRight(CGFloat(40*_pickers.count)).markDirty()
        
        textView.change(text: textView.originText.value) //this is a hack to get the text field to redraw to its new size
        
        if (_pickers.contains(.qrScan)) {
            qrScanButton.flex.width(35).height(35).markDirty()
            qrScanButton.isHidden = false
        } else {
            qrScanButton.flex.width(0).height(0).markDirty()
            qrScanButton.isHidden = true
        }
        
        if (_pickers.contains(.addressBook)) {
            addressBookButton.flex.width(35).height(35).markDirty()
            addressBookButton.isHidden = false
        } else {
            addressBookButton.flex.width(0).height(0).markDirty()
            addressBookButton.isHidden = true
        }
        
        if (_pickers.contains(.subaddress)) {
            subaddressButton.flex.width(35).height(35).marginLeft(0).markDirty()
            subaddressButton.isHidden = false
        } else {
            subaddressButton.flex.width(0).height(0).marginLeft(0).markDirty()
            subaddressButton.isHidden = true
        }
        
        textView.flex.layout()
        buttonsView.flex.width(CGFloat(40*_pickers.count)).markDirty()
        buttonsView.flex.layout()
        rootFlexContainer.flex.layout()

    }
    
    @objc
    private func scanQr() {
        QRReaderVC.modalPresentationStyle = .overFullScreen
        presenter?.parent?.present(QRReaderVC, animated: true)
    }
    
    @objc
    private func fromAddressBook() {
        let addressBookVC = AddressBookViewController(addressBook: AddressBook.shared, store: store, isReadOnly: true)
        addressBookVC.doneHandler = { [weak self] address in
            self?.textView.originText.accept(address)
        }
        let sendNavigation = UINavigationController(rootViewController: addressBookVC)
        presenter?.present(sendNavigation, animated: true)
    }
    
    @objc private func fromSubaddress() {
        let subaddressVC = SubaddressPickerViewController(store:store, isReadOnly: true)
        subaddressVC.doneHandler = { [weak self] address in
            self?.textView.originText.accept(String(address))
        }
        
        let sendNavigation = UINavigationController(rootViewController: subaddressVC)
        presenter?.present(sendNavigation, animated: true)
    }
    
    private func updateAddress(from uri: QRUri) {
        textView.originText.accept(uri.address)
    }
}
