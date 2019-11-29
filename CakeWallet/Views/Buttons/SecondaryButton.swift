import UIKit

class SecondaryButton: Button {
    override func configureView() {
        super.configureView()
        //tstag
        backgroundColor = UserInterfaceTheme.current.grayButton.fill
        layer.borderWidth = 0.75
        layer.borderColor = UserInterfaceTheme.current.grayButton.border.cgColor
    }
}
