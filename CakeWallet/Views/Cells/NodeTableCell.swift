import UIKit
import FlexLayout

final class NodeTableCell: FlexCell {
    static let height = 56 as CGFloat
    
    let addressLabel: UILabel
    let indicatorView: UIView
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        indicatorView = UIView(frame: CGRect(origin: .zero, size: CGSize(width: 10, height: 10)))
        addressLabel = UILabel(fontSize: 16)

        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }
    
    override func configureView() {
        super.configureView()
        addressLabel.font = applyFont(ofSize: 16)
        indicatorView.layer.masksToBounds = false
        indicatorView.layer.cornerRadius = 5

    }
    
    override func configureConstraints() {
        super.configureConstraints()
        contentView.flex
            .height(NodeTableCell.height)
            .direction(.row)
            .justifyContent(.spaceBetween)
            .alignSelf(.center)
            .define { flex in
                flex.addItem(addressLabel).marginLeft(20)
                flex.addItem(indicatorView).height(10).width(10).alignSelf(.center).marginRight(20)
                
        }
    }
    
    func configure(address: String, isAble: Bool, isCurrent: Bool) {
        addressLabel.text = address
        addressLabel.flex.markDirty()
        indicatorView.backgroundColor = isAble ? .green : .red
        self.isCurrent(isCurrent)
        contentView.flex.layout()
    }
}

final class LangTableCcell: FlexCell {
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }
    
    override func configureView() {
        super.configureView()
        contentView.layer.masksToBounds = false
        contentView.backgroundColor = UserInterfaceTheme.current.background
        backgroundColor = .clear
//        contentView.layer.applySketchShadow(color: .wildDarkBlue, alpha: 0.25, x: 10, y: 3, blur: 13, spread: 2)
        textLabel?.font = UIFont.systemFont(ofSize: 14) //fixme
        selectionStyle = .none
    }
    
    override func configureConstraints() {
        guard let textLabel = self.textLabel else {
            return
        }
        
        contentView.flex
            .margin(UIEdgeInsets(top: 7, left: 0, bottom: 0, right: 0))
            .padding(0, 20, 0, 20)
            .height(50)
            .direction(.row)
            .justifyContent(.spaceBetween)
            .alignSelf(.center)
            .define { flex in
                flex.addItem(textLabel)
        }
    }
    
    func configure(lang: Languages, isCurrent: Bool) {
        textLabel?.text = lang.formatted()
        contentView.backgroundColor = isCurrent ? UserInterfaceTheme.current.purple.main : UserInterfaceTheme.current.gray.dim
        textLabel?.textColor = isCurrent ? UserInterfaceTheme.current.text : UserInterfaceTheme.current.textVariants.main
        contentView.flex.layout()
    }
}
