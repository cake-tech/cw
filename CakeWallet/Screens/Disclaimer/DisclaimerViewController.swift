import UIKit

final class DisclaimerViewController: BaseViewController<DisclaimerView> {
    var onAccept: ((UIViewController) -> Void)? = { vc in
        UserDefaults.standard.set(true, forKey: Configurations.DefaultsKeys.termsOfUseAccepted)
        vc.dismiss(animated: true)
    }
    
    var hasCheckbox:Bool
    
    required init(showingCheckbox:Bool = true) {
        hasCheckbox = showingCheckbox
    }
    
    override func configureBinds() {
        super.configureBinds()
        loadAndDisplayDocument()
        contentView.acceptButton.addTarget(self, action: #selector(onAccessAction), for: .touchUpInside)
        contentView.checkBoxTitleButton.addTarget(self, action: #selector(toggleCheckBox), for: .touchUpInside)
        navigationController?.isNavigationBarHidden = true
    }
    
    @objc
    private func onAccessAction() {
        if contentView.checkBox.isChecked || hasCheckbox == false {
            onAccept?(self)
        }
    }
    
    @objc
    func toggleCheckBox() {
        contentView.checkBox.isChecked = !contentView.checkBox.isChecked
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if hasCheckbox == false {
            contentView.hasCheckbox = false
        }
    }
    override var prefersStatusBarHidden: Bool {
        return navigationController?.isNavigationBarHidden == true
    }
    
    private func loadAndDisplayDocument() {
        if let docUrl = Configurations.termsOfUseUrl {
            do {
                let attributedText = try NSAttributedString(
                    url: docUrl,
                    options: [NSAttributedString.DocumentReadingOptionKey.documentType: NSAttributedString.DocumentType.rtf],
                    documentAttributes: nil)
                contentView.textView.attributedText = attributedText
                contentView.textView.textColor = UserInterfaceTheme.current.text
            } catch {
                print(error) // fixme
            }
        }
    }
}
