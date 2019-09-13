import UIKit

class SecondaryButton: Button {
    override func configureView() {
        super.configureView()
        //tstag
        backgroundColor = UserInterfaceTheme.current.gray.dim
        layer.borderWidth = 0.75
        layer.borderColor = UserInterfaceTheme.current.gray.main.cgColor
    }
}
