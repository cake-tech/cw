import UIKit
import CakeWalletLib
import CakeWalletCore
import FlexLayout
import SwiftyJSON
import SwipeCellKit


final class AddressBookViewController: BaseViewController<AddressBookView>, UITableViewDelegate, UITableViewDataSource, SwipeTableViewCellDelegate {
    let addressBook: AddressBook
    let store: Store<ApplicationState>
    let isReadOnly: Bool?
    var doneHandler: ((String) -> Void)?
    
    private var contacts: [Contact]
    
    init(addressBook: AddressBook, store: Store<ApplicationState>, isReadOnly: Bool?) {
        self.addressBook = addressBook
        self.store = store
        self.isReadOnly = isReadOnly
        contacts = addressBook.all()
        super.init()
    }
    
    override func configureBinds() {
        super.configureBinds()
        title = NSLocalizedString("address_book", comment: "")
        
        let backButton = UIBarButtonItem(title: "", style: .plain, target: self, action: nil)
        navigationItem.backBarButtonItem = backButton

        contentView.table.delegate = self
        contentView.table.dataSource = self
        contentView.table.register(items: [Contact.self])
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        refreshContacts()
        
        let isModal = self.isModal
        renderActionButtons(for: isModal)
    }
    
    private func renderActionButtons(for isModal: Bool) {
        if !isModal {
            let addButton = makeIconedNavigationButton(iconName: "add_icon_purple", target: self, action: #selector(addNewAddressItem))
            navigationItem.rightBarButtonItems = [addButton]
        } else {
            navigationItem.leftBarButtonItem = UIBarButtonItem(
                image: UIImage(named:"close_symbol")?.resized(to:CGSize(width: 12, height: 12)),
                style: .plain,
                target: self,
                action: #selector(dismissAction)
            )
        }
    }
    
    private func refreshContacts() {
        contacts = addressBook.all()
        contentView.table.reloadData()
    }
    
    @objc
    private func dismissAction() {
        dismiss(animated: true) { [weak self] in
            self?.onDismissHandler?()
        }
    }
    
    @objc
    private func addNewAddressItem(){
        navigationController?.pushViewController(NewAddressViewController(addressBoook: AddressBook.shared), animated: true)
    }
    
    @objc
    private func copyAction() {
        showDurationInfoAlert(title: NSLocalizedString("copied", comment: ""), message: "", duration: 1)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        tableView.backgroundView = contacts.count == 0 ? createNoDataLabel(with: tableView.bounds.size) : nil
        tableView.separatorStyle = .none
        return contacts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let contact = contacts[indexPath.row]
        let cell = tableView.dequeueReusableCell(withItem: contact, for: indexPath) as! SwipeTableViewCell
        cell.delegate = self
        cell.addSeparator()
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return AddressTableCell.height
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let contact = contacts[indexPath.row]
        
        if let isReadOnly = self.isReadOnly, isReadOnly {
            dismissAction()
            doneHandler?(contact.address)
        } else {
            let cancelAction = UIAlertAction(title: NSLocalizedString("cancel", comment: ""), style: .cancel, handler: nil)
            let copyAction = UIAlertAction(title: NSLocalizedString("copy", comment: ""), style: .default) { _ in
                UIPasteboard.general.string = contact.address
            }
            
            var actions = [cancelAction, copyAction]
            
            // fixme: hardcoded value .monero,
            // it must be depend on current wallet type or will be removed when send screen will support exchange
            if contact.type == .monero {
                let sendAction = UIAlertAction(title: NSLocalizedString("send", comment: ""), style: .default) { [weak self] _ in
                    guard let store = self?.store else { return }
                    
                    let sendVC = SendViewController(store: store, address: contact.address)
                    let sendNavigation = UINavigationController(rootViewController: sendVC)
                    self?.present(sendNavigation, animated: true)
                }
                
                actions.append(sendAction)
            }
            
            showInfoAlert(
                title: contact.name,
                message: contact.address,
                actions: [cancelAction, copyAction]
            )
        }
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath, for orientation: SwipeActionsOrientation) -> [SwipeAction]? {
        guard orientation == .right else { return nil }
        
        let editAction = SwipeAction(style: .default, title: "Edit") { [weak self] action, indexPath in
            guard let contact = self?.contacts[indexPath.row] else {
                return
            }
            
            let newContactVC = NewAddressViewController(
                addressBoook: AddressBook.shared,
                contact: contact
            )
            self?.navigationController?.pushViewController(newContactVC, animated: true)
        }
        editAction.image = UIImage(named: "edit_icon")?.resized(to: CGSize(width: 20, height: 20))
        
        
        let deleteAction = SwipeAction(style: .destructive, title: "Delete") { [weak self] action, indexPath in
            guard let uuid = self?.contacts[indexPath.row].uuid else {
                return
            }
            
            do {
                try self?.addressBook.delete(for: uuid)
                self?.contacts = self?.addressBook.all() ?? []
                self?.contentView.table.reloadData()
            } catch {
                self?.showErrorAlert(error: error)
            }
        }
        deleteAction.image = UIImage(named: "trash_icon")?.resized(to: CGSize(width: 23, height: 23))
        
        return [deleteAction, editAction]
    }
    
    private func createNoDataLabel(with size: CGSize) -> UIView {
        let noDataLabel: UILabel = UILabel(frame: CGRect(origin: .zero, size: size))
        noDataLabel.text = NSLocalizedString("no_contacts", comment: "")
        noDataLabel.textColor = UIColor(hex: 0x9bacc5)
        noDataLabel.textAlignment = .center
        
        return noDataLabel
    }
}
