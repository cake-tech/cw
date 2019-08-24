import UIKit
import CakeWalletLib
import CakeWalletCore
import FlexLayout
import CWMonero
import SwipeCellKit

final class AddressPickerViewController: BaseViewController<AddressPickerView>, UITableViewDelegate, UITableViewDataSource {
    let store: Store<ApplicationState>
    let isReadOnly: Bool
    var doneHandler: ((String) -> Void)?
    
    private var subaddresses = [Subaddress]()
    
    init(store: Store<ApplicationState>, isReadOnly:Bool = false) {
        self.store = store
        self.isReadOnly = isReadOnly
        super.init()
    }
    
    override func configureBinds() {
        super.configureBinds()
        title = NSLocalizedString("subaddresses", comment: "")
        
        let backButton = UIBarButtonItem(title: "", style: .plain, target: self, action: nil)
        navigationItem.backBarButtonItem = backButton
        
        contentView.table.delegate = self
        contentView.table.dataSource = self
        contentView.table.register(items: [Contact.self])
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        refresh()
        
        let isModal = self.isModal
        renderActionButtons(for: isModal)
    }
    
    public func refresh() {
        subaddresses = store.state.subaddressesState.subaddresses
        contentView.table.reloadData()
    }
    
    private func renderActionButtons(for isModal: Bool) {
        let doneButton = StandartButton.init(image: UIImage(named: "close_symbol")?.resized(to: CGSize(width: 12, height: 12)))
        doneButton.frame = CGRect(origin: .zero, size: CGSize(width: 32, height: 32))
        doneButton.addTarget(self, action: #selector(dismissAction), for: .touchUpInside)
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: doneButton)
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
        dismissAction()
        doneHandler?(subaddresses[indexPath.row].label)
    }
    
    private func createNoDataLabel(with size: CGSize) -> UIView {
        let noDataLabel: UILabel = UILabel(frame: CGRect(origin: .zero, size: size))
        noDataLabel.text = NSLocalizedString("no_contacts", comment: "")
        noDataLabel.textColor = UIColor(hex: 0x9bacc5)
        noDataLabel.textAlignment = .center
        
        return noDataLabel
    }
}
