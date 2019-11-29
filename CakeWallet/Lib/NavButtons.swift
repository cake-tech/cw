import UIKit


func makeIconedNavigationButton(iconName: String, target: Any? = nil, action: Selector? = nil, iconSize: Int = 26) -> UIBarButtonItem {
    let button = UIBarButtonItem.init(
        image: UIImage(named: iconName)?.resized(to: CGSize(width: iconSize, height: iconSize)).withRenderingMode(.alwaysOriginal),
        style: .plain,
        target: target,
        action: action
    )
    button.tintColor = UserInterfaceTheme.current.purple.main
    
    return button
}

func makeTitledNavigationButton(title: String, target: Any? = nil, action: Selector? = nil, fontSize: CGFloat = 16, textColor: UIColor = UserInterfaceTheme.current.textVariants.highlight) -> UIBarButtonItem {
    let button = UIBarButtonItem(title: title, style: .plain, target: target, action: action)
    button.tintColor = UserInterfaceTheme.current.purple.main
    
    button.setTitleTextAttributes([
        NSAttributedStringKey.font: applyFont(ofSize: fontSize),
        NSAttributedStringKey.foregroundColor: textColor],
                                  for: .normal)
    
    button.setTitleTextAttributes([
        NSAttributedStringKey.font: applyFont(ofSize: fontSize),
        NSAttributedStringKey.foregroundColor: textColor],
                                  for: .highlighted)
    
    return button
}
