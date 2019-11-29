import UIKit
import FlexLayout
import CakeWalletLib
import CakeWalletCore
import LocalAuthentication

final class AuthenticationViewController: BaseViewController<BaseFlexView> {
    let pinCodeViewController: PinCodeViewController
    let authentication: Authentication
    let store: Store<ApplicationState>
    var handler: (() -> Void)?
    
    init(store: Store<ApplicationState>, authentication: Authentication) {
        self.authentication = authentication
        self.store = store
        self.pinCodeViewController = PinCodeViewController()
        super.init()
        modalPresentationStyle = .fullScreen
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        contentView.rootFlexContainer.flex.define({ flex in
            flex.addItem(pinCodeViewController.contentView).height(100%).width(100%)
        })
        
        if store.state.settingsState.isBiometricAuthenticationAllowed {
            authentication.biometricAuthentication { [weak self] res in
                DispatchQueue.main.async {
                    switch res {
                    case .success(_):
                        self?.handler?()
                    case let .failed(error):
                        self?.showErrorAlert(error: error)
                    }
                }
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        guard navigationController != nil else { return }
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(named:"close_symbol")?.resized(to:CGSize(width: 12, height: 12)),
            style: .plain,
            target: self,
            action: #selector(dismissAction)
        )

    }
    
    override func configureBinds() {
        pinCodeViewController.handler = { [weak self] pin in
            self?.authentication.authenticate(pin: pin.string(), handler: { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(_):
                        self?.handler?()
                    case let .failed(error):
                        if case AuthenticationError.incorrectPassword = error {
                            self?.pinCodeViewController.executeErrorAnimation()
                            return
                        }
                        
                        self?.showErrorAlert(error: error) {
                            self?.pinCodeViewController.cleanPin()
                        }
                    }
                }
            })
        }
    }
    
    @objc
    private func dismissAction() {
        dismiss(animated: true) { [weak self] in
            self?.onDismissHandler?()
        }
    }
}
