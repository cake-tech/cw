import Foundation
import UIKit
import FlexLayout

final class AboutSeedView: BaseFlexView {
    let imageView: UIImageView
    let titleLabel: UILabel
    
    let secondLabel: UILabel
    
    let understandButton: PrimaryButton
    
    required init() {
        imageView = UIImageView(image: UIImage(named:"seed_illu"))
        titleLabel = UILabel(fontSize: 19)
        titleLabel.textColor = UserInterfaceTheme.current.text
        titleLabel.text = NSLocalizedString("next_page_seed", comment: "")
        titleLabel.lineBreakMode = .byWordWrapping
        titleLabel.numberOfLines = 0
        titleLabel.textAlignment = .center
        
        secondLabel = UILabel(fontSize: 14)
        secondLabel.textColor = UserInterfaceTheme.current.textVariants.main
        secondLabel.text = NSLocalizedString("next_page_seed_instructions", comment:"")
        secondLabel.numberOfLines = 0
        secondLabel.lineBreakMode = .byWordWrapping
        secondLabel.textAlignment = .center
        
        understandButton = PrimaryButton(title: NSLocalizedString("i_understand", comment: ""))
        
        super.init()
    }
    
    override func configureView() {
        super.configureView()
        imageView.contentMode = .scaleAspectFit
    }
    
    override func configureConstraints() {
        let bottomView = UIView()
        bottomView.flex.define { flex in
            flex.addItem(understandButton).height(56).marginLeft(30).marginRight(30)
        }
        
        let mainView = UIView()
        mainView.flex.alignItems(.center).justifyContent(.center).define { flex in
            flex.addItem(imageView)
            flex.addItem(titleLabel).width(200).height(200)
            flex.addItem(secondLabel).marginBottom(30).width(260)
        }
        
        rootFlexContainer.flex.alignItems(.center).justifyContent(.center).define{ flex in
            flex.addItem(mainView)
            flex.addItem(bottomView).height(130).position(.absolute).bottom(0).width(100%).backgroundColor(UserInterfaceTheme.current.background)
        }
    }
}
