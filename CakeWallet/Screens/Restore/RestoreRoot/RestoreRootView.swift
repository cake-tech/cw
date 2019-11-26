import UIKit
import FlexLayout

final class RestoreRootView: BaseScrollFlexView {
    override var themedBackgroundColor:UIColor {
        get {
            return .clear
        }
    }
    
    let restoreWalletImageView: FlexView
    let restoreWalletImage: UIImageView
    let restoreWalletCard: WelcomeFlowCardView
    
    let restoreAppImageView: FlexView
    let restoreAppImage: UIImageView
    let restoreAppCard: WelcomeFlowCardView
    
    required init() {
        restoreWalletImageView = FlexView()
        restoreWalletImageView.backgroundColor = .clear
        restoreWalletImage = UIImageView(image: UIImage(named: "restore_wallet_image"))
        restoreWalletCard = WelcomeFlowCardView(
            imageView: restoreWalletImageView,
            titleText: NSLocalizedString("restore_from_seed_keys", comment: ""),
            descriptionText: NSLocalizedString("restore_from_seed_keys_long", comment: ""),
            textColor: UserInterfaceTheme.current.purple.highlight
        )

        restoreAppImageView = FlexView()
        restoreAppImageView.backgroundColor = .clear
        restoreAppImage = UIImageView(image: UIImage(named: "restore_app_image"))
        restoreAppCard = WelcomeFlowCardView(
            imageView: restoreAppImageView,
            titleText: NSLocalizedString("restore_from_backup", comment: ""),
            descriptionText: NSLocalizedString("restore_from_backup_long", comment: ""),
            textColor: UserInterfaceTheme.current.blue.highlight
        )

        super.init()
    }
    
    override func configureConstraints() {
//        let imageViewBackgroundColor = UserInterfaceTheme.current.restoreCardBackground
        let imageHeight = adaptiveLayout.getSize(forLarge: 180, forBig: 150, defaultSize: 115)
        let imageWidth = adaptiveLayout.getSize(forLarge: 360, forBig: 320, defaultSize: 240)
        
        restoreWalletImageView.constraintsSetup = { [weak self] root in
            root.flex.padding(5, 0, 10, 0).define { flex in
                if let restoreWalletImage = self?.restoreWalletImage {
                    flex.addItem(restoreWalletImage)
                        .height(imageHeight)
                        .width(imageWidth)
                }
            }
        }
        
        restoreAppImageView.constraintsSetup = { [weak self] root in
            root.flex.padding(5, 0, 10, 0).define { flex in
                if let restoreAppImage = self?.restoreAppImage {
                    flex.addItem(restoreAppImage)
                        .height(imageHeight)
                        .width(imageWidth)
                }
            }
        }
        
        rootFlexContainer.flex.alignItems(.center).padding(15, 20, 15, 20).define { flex in
            flex.addItem(restoreWalletCard).width(100%)
            flex.addItem(restoreAppCard).width(100%)
        }
        backgroundColor = UserInterfaceTheme.current.restoreScreenBackground
    }
}

