import UIKit
import FlexLayout


class LeftAlignedIconButton: Button {
    override func titleRect(forContentRect contentRect: CGRect) -> CGRect {
        let titleRect = super.titleRect(forContentRect: contentRect)
        let imageSize = currentImage?.size ?? .zero
        let availableWidth = contentRect.width - imageEdgeInsets.right - imageSize.width*2 - titleRect.width
        return titleRect.offsetBy(dx: round(availableWidth / 2), dy: 0)
    }
}


final class WalletsView: BaseScrollFlexViewWithBottomSection {
    let walletsTableView: UITableView
    let walletsCardView: CardView
    let createWalletButton: LeftAlignedIconButton
    let restoreWalletButton: LeftAlignedIconButton

    required init() {
        walletsTableView = UITableView()
        walletsCardView = CardView()
        createWalletButton = LeftAlignedIconButton(title: NSLocalizedString("create_new_wallet", comment: ""))
        restoreWalletButton = LeftAlignedIconButton(title: NSLocalizedString("restore_wallet", comment: ""))
        createWalletButton.setTitleColor(UserInterfaceTheme.current.text, for:.normal)
        restoreWalletButton.setTitleColor(UserInterfaceTheme.current.text, for: .normal)
        super.init()
    }
    
    override func configureView() {
        super.configureView()
        walletsTableView.rowHeight = 50
        walletsTableView.isScrollEnabled = false
        walletsTableView.backgroundColor = .clear
        
        createWalletButton.setImage(UIImage(named: "add_icon_purple")?.resized(to: CGSize(width: 30, height: 30)).withRenderingMode(.alwaysTemplate), for: .normal)
        restoreWalletButton.setImage(UIImage(named: "recover_icon")?.withRenderingMode(.alwaysTemplate), for: .normal)
        
        createWalletButton.imageView?.tintColor = UserInterfaceTheme.current.purple.highlight
        restoreWalletButton.imageView?.tintColor = UserInterfaceTheme.current.textVariants.highlight
        
        createWalletButton.imageEdgeInsets = UIEdgeInsets(top:0, left:10, bottom:0, right:0)
        restoreWalletButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 0)
        
        createWalletButton.contentHorizontalAlignment = .left
        restoreWalletButton.contentHorizontalAlignment = .left
       
        createWalletButton.layer.backgroundColor = UserInterfaceTheme.current.purple.dim.cgColor
        restoreWalletButton.layer.backgroundColor = UserInterfaceTheme.current.grayButton.fill.cgColor
        
        createWalletButton.layer.borderColor = UserInterfaceTheme.current.purple.main.cgColor
        restoreWalletButton.layer.borderColor = UserInterfaceTheme.current.grayButton.border.cgColor
        
        createWalletButton.layer.borderWidth = 1
        restoreWalletButton.layer.borderWidth = 1

        createWalletButton.setTitleColor(UserInterfaceTheme.current.textVariants.highlight, for: .normal)
        restoreWalletButton.setTitleColor(UserInterfaceTheme.current.textVariants.highlight, for: .normal)
        
        
        
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
