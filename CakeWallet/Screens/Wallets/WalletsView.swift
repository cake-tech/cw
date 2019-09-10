import UIKit
import FlexLayout

final class WalletsView: BaseScrollFlexViewWithBottomSection {
    let walletsTableView: UITableView
    let walletsCardView: CardView
    let createWalletButton: UIButton
    let restoreWalletButton: UIButton

    required init() {
        walletsTableView = UITableView()
        walletsCardView = CardView()
        createWalletButton = StandardButton(title: NSLocalizedString("create_new_wallet", comment: ""))
        restoreWalletButton = StandardButton(title: NSLocalizedString("restore_wallet", comment: ""))
        super.init()
    }
    
    override func configureView() {
        super.configureView()
        walletsTableView.rowHeight = 50
        walletsTableView.isScrollEnabled = false
        walletsTableView.backgroundColor = .clear
        createWalletButton.setImage(UIImage(named: "add_icon_purple")?.resized(to: CGSize(width: 30, height: 30)), for: .normal)
        createWalletButton.titleEdgeInsets = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 0)
        createWalletButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 0)
        createWalletButton.contentHorizontalAlignment = .left
        createWalletButton.layer.backgroundColor = UserInterfaceTheme.current.purple.dim.cgColor
        createWalletButton.layer.borderColor = UserInterfaceTheme.current.purple.highlight.cgColor
        createWalletButton.layer.borderWidth = 1
        restoreWalletButton.setImage(UIImage(named: "recover_icon")?.withRenderingMode(.alwaysTemplate), for: .normal)
        restoreWalletButton.imageView?.tintColor = UserInterfaceTheme.current.blue.main
        restoreWalletButton.titleEdgeInsets = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 0)
        restoreWalletButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 0)
        restoreWalletButton.contentHorizontalAlignment = .left
        restoreWalletButton.layer.backgroundColor = UserInterfaceTheme.current.blue.dim.cgColor
        restoreWalletButton.layer.borderColor = UserInterfaceTheme.current.blue.main.cgColor
        restoreWalletButton.layer.borderWidth = 1
        backgroundColor = UserInterfaceTheme.current.background
//        contentView.backgroundColor = .white
//        scrollView.backgroundColor = .white
    }
    
    override func configureConstraints() {
        let adaptivePadding = adaptiveLayout.getSize(forLarge: 40, forBig: 35, defaultSize: 30)
        
        rootFlexContainer.flex.backgroundColor(UserInterfaceTheme.current.background).padding(0, 20, 20, adaptivePadding).define { flex in
            flex.addItem(walletsTableView).marginTop(20)
        }
        
        bottomSectionView.flex.padding(0, 15, 0, 15).define { flex in
            flex.addItem(createWalletButton).height(72)
            flex.addItem(restoreWalletButton).height(72).marginTop(10)
        }
    }
}
