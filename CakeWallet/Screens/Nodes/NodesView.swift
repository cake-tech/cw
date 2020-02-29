import UIKit
import FlexLayout

final class NodesView: BaseFlexView {
    let table: UITableView
    
    required init() {
        table = UITableView()
        super.init()
    }
    
    override func configureView() {
        super.configureView()
        table.tableFooterView = UIView()
        table.backgroundColor = .clear
        table.separatorStyle = .none
        backgroundColor = UserInterfaceTheme.current.background
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        let height = self.rootFlexContainer.frame.size.height - 60
        table.flex.height(height).width(100%).markDirty()
        rootFlexContainer.flex.layout(mode: .adjustHeight)
    }
    
    override func configureConstraints() {
        rootFlexContainer.flex
            .backgroundColor(UserInterfaceTheme.current.background)
            .define { flex in
                flex.addItem(table).width(100%).marginTop(15)
        }
    }
}
