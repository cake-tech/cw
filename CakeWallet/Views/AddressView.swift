import UIKit
import FlexLayout
import QRCodeReader

public enum AddressViewPickers:UInt8 {
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
            configureConstraints()
            rootFlexContainer.setNeedsLayout()
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
    
    required init(placeholder: String = "", pickers:[AddressViewPickers] = [AddressViewPickers.qrScan]) {
        self.placeholder = placeholder
        textView = AddressTextField()
        borderView = UIView()
        buttonsView = UIView()
        qrScanButton = UIButton()
        addressBookButton = UIButton()
        subaddressButton = UIButton()
        _pickers = pickers.sorted(by: { return $0.rawValue > $1.rawValue })
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
        _pickers = [AddressViewPickers.qrScan]
        super.init()
    }
    
    override func configureView() {
        super.configureView()
        
        qrScanButton.imageEdgeInsets = UIEdgeInsetsMake(5, 5, 5, 5)
        qrScanButton.backgroundColor = .clear
        qrScanButton.layer.cornerRadius = 5
        qrScanButton.backgroundColor = UIColor.whiteSmoke
        
        addressBookButton.imageEdgeInsets = UIEdgeInsetsMake(5, 5, 5, 5)
        addressBookButton.backgroundColor = .clear
        addressBookButton.layer.cornerRadius = 5
        addressBookButton.backgroundColor = UIColor.whiteSmoke
        
        subaddressButton.imageEdgeInsets = UIEdgeInsetsMake(5, 5, 5, 5)
        subaddressButton.backgroundColor = .clear
        subaddressButton.layer.cornerRadius = 5
        subaddressButton.backgroundColor = UIColor.whiteSmoke
        
        if let qrScanImage = UIImage(named: "qr_code_icon") {
            qrScanButton.setImage(qrScanImage, for: .normal)
        }
        
        if let addressBookImage = UIImage(named: "address_book") {
            addressBookButton.setImage(addressBookImage, for: .normal)
        }
        
        if let subaddressImage = UIImage(named: "receive_icon") {
            subaddressButton.setImage(subaddressImage, for: .normal)
        }
        
        qrScanButton.addTarget(self, action: #selector(scanQr), for: .touchUpInside)
        addressBookButton.addTarget(self, action: #selector(fromAddressBook), for: .touchUpInside)
        
        textView.font = applyFont(ofSize: 15, weight: .regular)
        textView.attributedPlaceholder = NSAttributedString(
            string: placeholder,
            attributes: [
                NSAttributedString.Key.foregroundColor: UIColor.wildDarkBlue,
                NSAttributedStringKey.font: UIFont(name: "Lato-Regular", size: CGFloat(15))!
            ]
        )

        textView.rightView = UIView(frame: CGRect(x: 0, y: 0, width: 40*availablePickers.count, height: 0))
        textView.rightView?.backgroundColor = .red
        textView.rightViewMode = .always
        backgroundColor = .clear
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        textView.change(text: textView.originText.value)
        
        buttonsView.flex.width(CGFloat(40*availablePickers.count))
        
        if (availablePickers.contains(.qrScan)) {
            qrScanButton.flex.width(35).height(35).marginLeft(5)
            qrScanButton.isHidden = false
        } else {
            qrScanButton.flex.width(0).height(0).marginLeft(0)
            qrScanButton.isHidden = true
        }
        
        if (availablePickers.contains(.addressBook)) {
            addressBookButton.flex.width(35).height(35).marginLeft(5)
            addressBookButton.isHidden = false
        } else {
            addressBookButton.flex.width(0).height(0).marginLeft(0)
            addressBookButton.isHidden = true
        }

        if (availablePickers.contains(.subaddress)) {
            subaddressButton.flex.width(35).height(35).marginLeft(5)
            addressBookButton.isHidden = false
        } else {
            subaddressButton.flex.width(0).height(0).marginLeft(0)
            addressBookButton.isHidden = true
        }

    }
    
    override func configureConstraints() {        
        buttonsView.flex
            .direction(.row)
            .justifyContent(.spaceBetween).alignItems(.end)
            .width(CGFloat(40*availablePickers.count))
            .define{ flex in
                    
                for (_, curPicker) in availablePickers.enumerated() {
                    switch curPicker {
                    case .qrScan:
                        flex.addItem(qrScanButton).width(35).height(35).marginLeft(5)
                    case .addressBook:
                        flex.addItem(addressBookButton).width(35).height(35).marginLeft(5)
                    case .subaddress:
                        flex.addItem(subaddressButton).width(35).height(35).marginLeft(5)
                    }
                }
        }
        
        rootFlexContainer.flex
            .width(100%)
            .backgroundColor(.clear)
            .define{ flex in
                flex.addItem(textView).backgroundColor(.clear).width(100%).marginBottom(11)
                flex.addItem(borderView).height(1.5).width(100%).backgroundColor(UIColor.veryLightBlue)
                flex.addItem(buttonsView).position(.absolute).top(-10).right(0)
        }
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
        let subaddressVC = AddressPickerViewController(store:store, isReadOnly: true)
        subaddressVC.doneHandler = { [weak self] address in
            self?.textView.originText.accept(address)
        }
    }
    
    private func updateAddress(from uri: QRUri) {
        textView.originText.accept(uri.address)
    }
}
