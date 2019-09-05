import UIKit

class SecondaryButton: Button {
    override func configureView() {
        super.configureView()
        //tstag
        backgroundColor = UserInterfaceTheme.current.gray.main
        layer.borderWidth = 0.75
        layer.borderColor = UIColor.grayBorder.cgColor
    }
}
