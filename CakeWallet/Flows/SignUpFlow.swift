import UIKit

final class SignUpFlow: Flow {
    let restoreWalletFlow: RestoreWalletFlow
    
    enum Route {
        case disclaimer
        case welcome
        case restoreRoot
        case newWallet
        case setupPin(((SignUpFlow) -> Void)?)
        case createWallet
        case restoreFromCloud
        case seed(Date, String, String)
    }
    
    var rootController: UIViewController {
        return navigationController
    }
    
    var doneHandler: (() -> Void)? {
        didSet {
            self.restoreWalletFlow.doneHandler = doneHandler
        }
    }
    
    private let navigationController: UINavigationController
    
    init(navigationController: UINavigationController, restoreWalletFlow: RestoreWalletFlow) {
        self.navigationController = navigationController
        self.restoreWalletFlow = restoreWalletFlow
    }
    
    func change(route: Route) {
        switch route {
        case .seed(_, _, _):
            let vc = initedViewController(for: route) as! AboutSeedViewController
            self.navigationController.present(vc, animated: true, completion: nil)
        default:
             navigationController.pushViewController(initedViewController(for: route), animated: true)
        }
       
    }
    
    private func initedViewController(for route: Route) -> UIViewController {
        switch route {
        case .disclaimer:
            let vc = DisclaimerViewController()
            vc.onAccept = { [weak self] _ in
                UserDefaults.standard.set(true, forKey: Configurations.DefaultsKeys.termsOfUseAccepted)
                self?.change(route: .welcome)
            }
            
            return vc
        case .welcome:
            return WelcomeViewController(signUpFlow: self, restoreWalletFlow: restoreWalletFlow)
        case .newWallet:
            return NewWalletViewController(signUpFlow: self, restoreWalletFlow: restoreWalletFlow)
        case .restoreRoot:
            return RestoreRootVC(signUpFlow: self, restoreWalletFlow: restoreWalletFlow)
        case let .setupPin(handler):
            let setupPinController = SetupPinViewController(store: store)
            setupPinController.afterPinSetup = { handler?(self) }
            return setupPinController
        case .createWallet:
            return CreateWalletViewController(signUpFlow: self, store: store)
        case let .seed(date, walletName, seed):
            let aboutSeed = AboutSeedViewController(store: store)
            aboutSeed.onDismissHandler = { [weak self] in
                guard let self = self else {
                    return
                }
                let seedViewController = SeedViewController(walletName: walletName, date: date, seed: seed, doneFlag: true)
                seedViewController.doneHandler = self.doneHandler
                self.navigationController.pushViewController(seedViewController, animated: true)
            }
            return aboutSeed
        case .restoreFromCloud:
            let restoreFromCloudVC = RestoreFromCloudVC(backup: BackupServiceImpl(), storage: ICloudStorage())
            restoreFromCloudVC.doneHandler = doneHandler
            return restoreFromCloudVC
        }
    }
}
