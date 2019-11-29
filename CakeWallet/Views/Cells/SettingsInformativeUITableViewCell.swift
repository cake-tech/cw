import UIKit
import CakeWalletLib

final class SettingsInformativeUITableViewCell: FlexCell, UITextFieldDelegate {
    let accessoryTextField: UITextField
    
    var _infBlue:Bool = false
    var informativeBlue: Bool {
        set {
            if newValue == true {
                accessoryTextField.textColor = UserInterfaceTheme.current.blue.highlight
                _infBlue = true
            } else {
                accessoryTextField.textColor = UserInterfaceTheme.current.textVariants.main
                _infBlue = false
            }
        }
        get {
            return _infBlue
        }
    }

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        accessoryTextField = UITextField()
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }
    
    override func configureView() {
        super.configureView()
        accessoryView = accessoryTextField
        textLabel?.textColor = UserInterfaceTheme.current.text
        accessoryTextField.textAlignment = .right
        accessoryTextField.textColor = UserInterfaceTheme.current.textVariants.main
        accessoryTextField.backgroundColor = .clear
        accessoryTextField.delegate = self
        accessoryTextField.isUserInteractionEnabled = false
        
        selectionStyle = .gray
        let bgView = UIView()
        bgView.backgroundColor = UserInterfaceTheme.current.gray.dim
        selectedBackgroundView = bgView

    }
    
    override func configureConstraints() {
        accessoryTextField.frame = CGRect(origin: .zero, size: CGSize(width: 215, height: 50))
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
