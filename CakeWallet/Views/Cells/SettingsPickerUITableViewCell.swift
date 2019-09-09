import UIKit
import CakeWalletLib

final class SettingsPickerUITableViewCell<Item: Formatted>: FlexCell, UIPickerViewDelegate, UIPickerViewDataSource, UITextFieldDelegate {
    typealias Action = ((Item) -> Void)?
    var onFinish: Action
    let pickerView: UIPickerView
    let pinckerTextField: UITextField
    private(set) var pickerOptions: [Item]
    private var action: Action
    private let initialSelectedOption: Item?
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        pickerView = UIPickerView()
        pinckerTextField = UITextField()
        pickerOptions = []
        initialSelectedOption = nil
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }
    
    override func configureView() {
        super.configureView()
        accessoryView = pinckerTextField
        pinckerTextField.textAlignment = .right
        pinckerTextField.inputView = pickerView
        
        //tstag
        pinckerTextField.textColor = UserInterfaceTheme.current.textVariants.highlight
        pinckerTextField.backgroundColor = UserInterfaceTheme.current.background
        backgroundColor = UserInterfaceTheme.current.background
        pickerView.delegate = self
        pickerView.dataSource = self
        pinckerTextField.delegate = self
        let onTapGesture = UITapGestureRecognizer(target: self, action: #selector(onTap))
        addGestureRecognizer(onTapGesture)
    }
    
    override func configureConstraints() {
        pinckerTextField.frame = CGRect(origin: .zero, size: CGSize(width: 200, height: 50))
    }
    
    func configure(title: String, pickerOptions: [Item], selectedOption: Int = 0, action: Action) {
        self.textLabel?.text = title
        self.pickerOptions = pickerOptions
        self.action = action
        pickerView.reloadAllComponents()
        pickerView.selectRow(selectedOption, inComponent: 0, animated: false)
        pinckerTextField.text = stringForPickerOption(pickerOptions[selectedOption])
    }
    
    //returns the localized string for inputItem if the Item supports LocalizedFormat, else returns formatted() value from
    private func stringForPickerOption(_ inputItem:Item) -> String {
        if let asLocalized = (inputItem as? LocalizedFormat) {
            return asLocalized.localizedString()
        } else {
            return inputItem.formatted()
        }

    }
    
    // MARK: UIPickerViewDelegate
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        guard pickerOptions.count >= row else {
            return ""
        }
        
        return stringForPickerOption(pickerOptions[row])
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        let selOp = pickerOptions[row]
        pinckerTextField.text = stringForPickerOption(selOp)
        action?(selOp)
    }
    
    // MARK: UIPickerViewDataSource
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return pickerOptions.count
    }
    
    // MARK: UITextFieldDelegate
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        let selectedRow = pickerView.selectedRow(inComponent: 0)
        let selectedOption = pickerOptions[selectedRow]
        onFinish?(selectedOption)
    }
    
    @objc
    private func onTap() {
        pinckerTextField.becomeFirstResponder()
    }
}
