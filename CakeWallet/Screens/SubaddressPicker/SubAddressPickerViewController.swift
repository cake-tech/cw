import UIKit
import CakeWalletLib
import CakeWalletCore
import FlexLayout
import CWMonero
import SwipeCellKit

final class SubaddressPickerViewController: BaseViewController<SubaddressPickerView>, UITableViewDelegate, UITableViewDataSource, StoreSubscriber {
    let store: Store<ApplicationState>
    let isReadOnly: Bool
    var doneHandler: ((String) -> Void)?
    
    private var subaddresses = [Subaddress]()
    
    init(store: Store<ApplicationState>, isReadOnly:Bool = false) {
        self.store = store
        self.isReadOnly = isReadOnly
        store.dispatch(SubaddressesActions.update)
        super.init()
    }
    
    override func configureBinds() {
        super.configureBinds()
        title = NSLocalizedString("subaddresses", comment: "")
        store.subscribe(self, onlyOnChange: [\ApplicationState.subaddressesState])
        let backButton = UIBarButtonItem(title: "", style: .plain, target: self, action: nil)
        navigationItem.backBarButtonItem = backButton
        
        contentView.table.delegate = self
        contentView.table.dataSource = self
        contentView.table.register(items: [Subaddress.self])
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        let isModal = self.isModal
        renderActionButtons(for: isModal)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        refresh()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        store.unsubscribe(self)
    }
    
    func onStateChange(_ state: ApplicationState) {
        refresh()
    }

    public func refresh() {
        subaddresses = store.state.subaddressesState.subaddresses
        contentView.table.reloadData()
    }
    
    private func renderActionButtons(for isModal: Bool) {
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(named:"close_symbol")?.resized(to:CGSize(width: 12, height: 12)),
            style: .plain,
            target: self,
            action: #selector(dismissAction)
        )
    }
    
    @objc
    private func dismissAction() {
        dismiss(animated: true) { [weak self] in
            self?.onDismissHandler?()
        }
    }

    @objc
    private func copyAction() {
        showDurationInfoAlert(title: NSLocalizedString("copied", comment: ""), message: "", duration: 1)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        tableView.separatorStyle = .none
        return subaddresses.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let thisSubaddress = subaddresses[indexPath.row]
        let cell = tableView.dequeueReusableCell(withItem: thisSubaddress, for: indexPath) as! SubaddressCell
        cell.addSeparator()
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return AddressTableCell.height
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        doneHandler?(subaddresses[indexPath.row].address)
        dismissAction()
    }
    
    private func createNoDataLabel(with size: CGSize) -> UIView {
        let noDataLabel: UILabel = UILabel(frame: CGRect(origin: .zero, size: size))
        noDataLabel.text = NSLocalizedString("no_contacts", comment: "")
        noDataLabel.textColor = UIColor(hex: 0x9bacc5)
        noDataLabel.textAlignment = .center
        
        return noDataLabel
    }
}
