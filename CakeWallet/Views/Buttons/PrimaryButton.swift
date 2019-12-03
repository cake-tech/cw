import UIKit

final class PrimaryButton: Button {
    override func layoutSubviews() {
        super.layoutSubviews()
        
        layer.borderWidth = 0.75
    }
}
