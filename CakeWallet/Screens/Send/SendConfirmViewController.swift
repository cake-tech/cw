import Foundation
import CakeWalletCore
import CWMonero


final class SendConfirmViewController: BaseViewController<SendConfirmView> {
    weak var flow: DashboardFlow?
    let store: Store<ApplicationState>
    
    init(store: Store<ApplicationState>) {
        self.store = store
        super.init()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        title = NSLocalizedString("confirm_sending", comment: "")
    }
    
    override func configureBinds() {
        contentView.cancelButton.addTarget(self, action: #selector(userUnderstands), for: .touchDown)
    }
    
    @objc private func userUnderstands() {
        self.dismiss(animated: true)
    }
}
