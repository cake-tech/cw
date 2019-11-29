import UIKit

class CWNavigationBar: UINavigationBar {
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        return CGSize(width: frame.size.width, height: 60)
    }
}

class CWNavigationController: UINavigationController {
    
}
