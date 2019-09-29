import UIKit
import FlexLayout

final class RestoreRootView: BaseScrollFlexView {
    let restoreWalletImageView: FlexView
    let restoreWalletImage: UIImageView
    let restoreWalletCard: WelcomeFlowCardView
    
    let restoreAppImageView: FlexView
    let restoreAppImage: UIImageView
    let restoreAppCard: WelcomeFlowCardView
    
    required init() {
        restoreWalletImageView = FlexView()
        restoreWalletImage = UIImageView(image: UIImage(named: "restore_wallet_image"))
        restoreWalletCard = WelcomeFlowCardView(
            imageView: restoreWalletImageView,
            titleText: NSLocalizedString("restore_from_seed_keys", comment: ""),
            descriptionText: NSLocalizedString("restore_from_seed_keys_long", comment: ""),
            textColor: UserInterfaceTheme.current.purple.highlight
        )
        restoreWalletCard.layer.masksToBounds = false
        
        restoreAppImageView = FlexView()
        restoreAppImage = UIImageView(image: UIImage(named: "restore_app_image"))
        restoreAppCard = WelcomeFlowCardView(
            imageView: restoreAppImageView,
            titleText: NSLocalizedString("restore_from_backup", comment: ""),
            descriptionText: NSLocalizedString("restore_from_backup_long", comment: ""),
            textColor: UserInterfaceTheme.current.blue.highlight
        )
        restoreAppCard.layer.masksToBounds = false
        
        super.init()
    }
    
    override func configureConstraints() {
        //TSTAG
        let imageViewBackgroundColor = UserInterfaceTheme.current.settingBackgroundColor
        let imageHeight = adaptiveLayout.getSize(forLarge: 180, forBig: 150, defaultSize: 115)
        let imageWidth = adaptiveLayout.getSize(forLarge: 360, forBig: 320, defaultSize: 240)
        
        restoreWalletImageView.constraintsSetup = { [weak self] root in
            root.flex.padding(5, 0, 10, 0).backgroundColor(imageViewBackgroundColor).define { flex in
                if let restoreWalletImage = self?.restoreWalletImage {
                    flex.addItem(restoreWalletImage)
                        .height(imageHeight)
                        .width(imageWidth)
                }
            }
        }
        
        restoreAppImageView.constraintsSetup = { [weak self] root in
            root.flex.padding(5, 0, 10, 0).backgroundColor(imageViewBackgroundColor).define { flex in
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
    }
}

