import UIKit
import FlexLayout
import SwipeCellKit

class FlexCell: SwipeTableViewCell {
    static let identifier = String(describing: FlexCell.self)
    let separatorView: UIView
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        separatorView = UIView()
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        configureView()
        configureConstraints()
    }
    
    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        layout()
    }
    
    override func configureView() {
        super.configureView()
    }
    
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        contentView.pin.width(size.width)
        layout()
        let size = contentView.frame.size
        return size
    }
    
    override func configureConstraints() {
        contentView.flex.addItem(separatorView).position(.absolute).bottom(0).height(0.6).width(100%).backgroundColor(UserInterfaceTheme.current.gray.dim)
    }
    
    func layout() {
        contentView.flex.layout(mode: .adjustHeight)
    }
}
