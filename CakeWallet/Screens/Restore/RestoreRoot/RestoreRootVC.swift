import UIKit
import CakeWalletLib

final class RestoreRootVC: BaseViewController<RestoreRootView> {
    weak var signUpFlow: SignUpFlow?
    weak var restoreWalletFlow: RestoreWalletFlow?
    
    init(signUpFlow: SignUpFlow, restoreWalletFlow: RestoreWalletFlow) {
        self.signUpFlow = signUpFlow
        self.restoreWalletFlow = restoreWalletFlow
        super.init()
    }
    
    override func configureBinds() {
        title = "Restore"
        
        let backButton = UIBarButtonItem(title: "", style: .plain, target: self, action: nil)
        navigationItem.backBarButtonItem = backButton
        
        contentView.restoreWalletCard.button.addTarget(self, action: #selector(restoreWallet), for: .touchUpInside)
        contentView.restoreAppCard.button.addTarget(self, action: #selector(restoreApp), for: .touchUpInside)
        
        navigationController?.navigationBar.backgroundColor = UserInterfaceTheme.current.settingBackgroundColor
        contentView.backgroundColor = UserInterfaceTheme.current.settingBackgroundColor
    }

    @objc
    private func restoreWallet() {
        signUpFlow?.change(route: .setupPin({ [weak self] _ in
            self?.restoreWalletFlow?.change(route: .root)
        }))
    }
    
    @objc
    private func restoreApp() {
        signUpFlow?.change(route: .restoreFromCloud)
    }
    
    override func setBarStyle() {
        super.setBarStyle()
        navigationController?.navigationBar.backgroundColor = UserInterfaceTheme.current.settingBackgroundColor
        contentView.backgroundColor = UserInterfaceTheme.current.settingBackgroundColor
    }

}
