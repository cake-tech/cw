import UIKit
import FlexLayout

final class PickerTableCell: FlexCell {
    static let height = 64 as CGFloat
    
    let titleLabel: UILabel
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        titleLabel = UILabel()
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }
    
    override func configureView() {
        super.configureView()
        titleLabel.textAlignment = .center
        titleLabel.font = applyFont(ofSize: 17, weight: .semibold)
        selectionStyle = .none
        backgroundColor = UserInterfaceTheme.current.background
    }
    
    override func configureConstraints() {
        contentView.flex
            .paddingLeft(18)
            .paddingTop(20)
            .direction(.row)
            .justifyContent(.center)
            .alignItems(.center)
            .define { flex in
                flex.addItem(titleLabel).width(100%)
        }
    }
    
    func configure(text: String, isSelected: Bool) {
        titleLabel.text = text
        titleLabel.textColor = isSelected ? UserInterfaceTheme.current.blue.highlight : UserInterfaceTheme.current.textVariants.highlight
        contentView.flex.layout()
    }
}

