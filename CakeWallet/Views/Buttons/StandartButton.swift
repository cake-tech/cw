import UIKit

final class StandardButton: Button {
    override func configureView() {
        super.configureView()
        setTitleColor(UserInterfaceTheme.current.text, for: .normal)
    }
}
