import Foundation
import CakeWalletCore
import CWMonero


final class AboutSeedViewController: BaseViewController<AboutSeedView> {
    weak var flow: DashboardFlow?
    let store: Store<ApplicationState>
    
    init(store: Store<ApplicationState>) {
        self.store = store
        super.init()
        modalPresentationStyle = .fullScreen
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
    }
    
    override func configureBinds() {
        contentView.understandButton.addTarget(self, action: #selector(userUnderstands), for: .touchDown)
    }
    
    @objc private func userUnderstands() {
        self.dismiss(animated: true)
    }
}
