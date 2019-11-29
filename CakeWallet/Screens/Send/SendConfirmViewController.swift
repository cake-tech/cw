import Foundation
import CakeWalletCore
import CWMonero


final class SendConfirmViewController: BaseViewController<SendConfirmView> {
    var amount:String
    var address:String
    var fee:String
    
    var onAccept: (() -> Void)? = nil
    var onCancel: (() -> Void)? = nil
    
    init(amount:String, address:String, fee:String) {
        self.amount = amount
        self.address = address
        self.fee = fee
        super.init()
        title = NSLocalizedString("confirm_sending", comment: "")
        modalPresentationStyle = .fullScreen
    }
    
    override func viewWillAppear(_ animated: Bool) {
        navigationController?.navigationItem.title = NSLocalizedString("confirm_sending", comment: "")
        contentView.amountLabel.text = amount + " XMR"
        contentView.feeLabel.text = NSLocalizedString("fee", comment: "") + ": " + fee
        contentView.addressLabel.text = address
    }
    
    override func configureBinds() {
        contentView.cancelButton.addTarget(self, action: #selector(userCanceled), for: .touchDown)
        contentView.sendButton.addTarget(self, action: #selector(userAccepted), for: .touchDown)
    }
    
    
    @objc private func userCanceled() {
        if let hasCancelFunction = onCancel {
            hasCancelFunction()
        }
        self.dismiss(animated: true)
    }
    
    @objc private func userAccepted() {
        if let hasAcceptFunction = onAccept {
            hasAcceptFunction()
        }
        self.dismiss(animated: true)
    }
}
