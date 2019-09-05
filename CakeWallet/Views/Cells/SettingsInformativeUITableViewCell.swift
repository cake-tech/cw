import UIKit
import CakeWalletLib

final class SettingsInformativeUITableViewCell: FlexCell, UITextFieldDelegate {
    let accessoryTextField: UITextField
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        accessoryTextField = UITextField()
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }
    
    override func configureView() {
        super.configureView()
        accessoryView = accessoryTextField
        accessoryTextField.textAlignment = .right
        //TSTAG
        accessoryTextField.textColor = UserInterfaceTheme.current.textVariants.dim
        accessoryTextField.backgroundColor = .white
        accessoryTextField.delegate = self
        accessoryTextField.isUserInteractionEnabled = false
        backgroundColor = .white
    }
    
    override func configureConstraints() {
        accessoryTextField.frame = CGRect(origin: .zero, size: CGSize(width: 250, height: 50))
    }
    
    func configure(title: String, informativeText:String) {
        self.textLabel?.text = title
        accessoryTextField.text = informativeText
    }
    
    //MARK: UITextFieldDelegate functions
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        //do not allow the informative text in this cell to be edited or focused
        return false
    }
}
