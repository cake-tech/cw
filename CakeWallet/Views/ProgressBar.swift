import UIKit
import FlexLayout
import SwiftDate

let syncImageSize = CGSize(width: 12, height: 12)

final class ProgressBar: BaseFlexView {
    var currentTheme = UserInterfaceTheme.current
    
    let progressView: UIView
    let textContainer: UIView
    let imageHolder: UIImageView
    let syncImage: UIImage
    var primaryLabel: UILabel
    var secondaryLabel: UILabel
    
    public typealias ProgressInformation = (remaining:UInt64, track:UInt64)
    public enum ProgressBarDisplayConfiguration {
        case syncronized(String, String)
        case inProgress(String, String, ProgressInformation)
        case indeterminantMessage(String)
        case indeterminantSync(String)
        case error(String)
    }
    
    private var currentDisplayConfiguration = ProgressBarDisplayConfiguration.syncronized("", "")
    public var configuration:ProgressBarDisplayConfiguration {
        set {
            currentDisplayConfiguration = newValue
            displayConfigurationChanged()
        }
        get {
            return currentDisplayConfiguration
        }
    }
    private var _syncIndicatorVisible = false
    private var isSyncIndicatorVisible:Bool {
        get {
            return !imageHolder.isHidden
        }
        set {
            if (newValue == false) {
                imageHolder.layer.removeAllAnimations()
                imageHolder.flex.backgroundColor(.clear).height(0).width(0).marginLeft(0).markDirty()
                secondaryLabel.flex.width(100%).markDirty()
                imageHolder.isHidden = true

            } else {
                imageHolder.flex.backgroundColor(.clear).height(syncImageSize.height).width(syncImageSize.width).marginLeft(21).markDirty()
                secondaryLabel.flex.width(90%).markDirty()
                imageHolder.isHidden = false
                animateSyncImage()
            }
            imageHolder.flex.markDirty()
        }
    }
    private var isLastBlockDateVisible:Bool {
        get {
            return !secondaryLabel.isHidden
        }
        set {
            if (newValue == false) {
                secondaryLabel.isHidden = true
                secondaryLabel.text = ""
                secondaryLabel.flex.markDirty()
                rootFlexContainer.flex.layout()
            } else {
                secondaryLabel.isHidden = false
                updateLastBlockRelativeString()
            }
        }
    }
    private var _lastBlock:Date = Date()
    public var lastBlockDate:Date {
        set {
            _lastBlock = newValue
            updateLastBlockRelativeString()
        }
        get {
            return _lastBlock
        }
    }
    
    private var timerLaunched = false
    
    required init() {
        progressView = UIView()
        textContainer = UIView()
        imageHolder = UIImageView()
        syncImage = UIImage(named: "refresh_icon")!.resized(to:syncImageSize)
        primaryLabel = UILabel(text: "SYNCING BLOCKCHAIN")
        secondaryLabel = UILabel(text:"AS OF")
        
        super.init()
    }
    
    override func configureView() {
        super.configureView()
        
        imageHolder.image = syncImage
        imageHolder.backgroundColor = .clear
        primaryLabel.font = applyFont(ofSize: 12)
        primaryLabel.textColor = currentTheme.textVariants.highlight
        primaryLabel.textAlignment = .center
        secondaryLabel.font = applyFont(ofSize:10)
        secondaryLabel.textColor = currentTheme.textVariants.main
        secondaryLabel.textAlignment = .center
        progressView.layer.borderWidth = 1
        progressView.isOpaque = true
        if (timerLaunched == false) {
            self.launchRelativeDateDisplayTimer()
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        progressView.layer.masksToBounds = true
        progressView.layer.cornerRadius = progressView.frame.size.height / 2
    }
    
    override func configureConstraints() {
        textContainer.flex.backgroundColor(.clear).alignItems(.center).justifyContent(.center).define { flex in
            flex.addItem(primaryLabel).alignSelf(.center).width(100%)
            flex.addItem(secondaryLabel).alignSelf(.center).width(100%)
        }
        
        progressView.flex
            .direction(.row).backgroundColor(.clear).alignItems(.center).justifyContent(.center)
            .height(42).define { flex in
                flex.addItem(imageHolder).marginLeft(21)
                flex.addItem(textContainer).width(90%)
        }
        
        rootFlexContainer.flex
            .alignItems(.center).backgroundColor(.clear).justifyContent(.center)
            .width(100%)
            .define { flex in
                flex.addItem(progressView).width(210)
        }
    }
    
    public func themeChanged() {
        configureConstraints()
        displayConfigurationChanged()
        animateSyncImage()
    }
    
    private func animateSyncImage() {
        guard imageHolder.layer.animation(forKey: "rotate") == nil else {
            return
        }
        
        let animation = CAKeyframeAnimation(keyPath: "transform.rotation.z")
        animation.duration = 1.0
        animation.fillMode = kCAFillModeForwards
        animation.repeatCount = .infinity
        animation.values = [0, Double.pi / 2, Double.pi, Double.pi * 3 / 2, Double.pi * 2]
        let moments = [NSNumber(value: 0.0), NSNumber(value: 0.1),
                       NSNumber(value: 0.3), NSNumber(value: 0.8), NSNumber(value: 1.0)]
        animation.keyTimes = moments
        
        imageHolder.layer.add(animation, forKey: "rotate")
    }
    
    
    private typealias Colors = (border:UIColor, fill:UIColor)
    private func themeForConfiguration() -> Colors {
        switch currentDisplayConfiguration {
        case .syncronized(_, _):
            return (border:UserInterfaceTheme.current.red.dim, fill:UserInterfaceTheme.current.red.highlight)
        case .error(_):
            return (border:UserInterfaceTheme.current.red.dim, fill:UserInterfaceTheme.current.red.highlight)
        case .inProgress(_, _, _):
            return (border:currentTheme.gray.highlight, fill:currentTheme.gray.dim)
        case .indeterminantMessage(_):
            return (border:currentTheme.gray.highlight, fill:currentTheme.gray.dim)
        case .indeterminantSync(_):
            return (border:currentTheme.gray.highlight, fill:currentTheme.gray.dim)
        }
    }
    
    private func displayConfigurationChanged() {
        let colors = themeForConfiguration()
        
        primaryLabel.textColor = currentTheme.textVariants.highlight
        secondaryLabel.textColor = currentTheme.textVariants.main
        
        switch currentDisplayConfiguration {
        case let .syncronized(primaryLocalized, secondaryLocalizedPrefix):
            primaryLabel.text = primaryLocalized
            secondaryLabel.text = secondaryLocalizedPrefix + " " + lastBlockRelativeString()
            isLastBlockDateVisible = true
            isSyncIndicatorVisible = false
        case let .error(primaryLocalized):
            primaryLabel.text = primaryLocalized
            isLastBlockDateVisible = false
            isSyncIndicatorVisible = false
        case let .inProgress(primaryLocalized, secondaryLocalized, progressInformation):
            primaryLabel.text = primaryLocalized
            secondaryLabel.text = String(progressInformation.remaining) + " " + secondaryLocalized
            isLastBlockDateVisible = true
            isSyncIndicatorVisible = true
        case let .indeterminantMessage(message):
            primaryLabel.text = message
            isLastBlockDateVisible = false
            isSyncIndicatorVisible = false
        case let .indeterminantSync(message):
            primaryLabel.text = message
            isLastBlockDateVisible = false
            isSyncIndicatorVisible = true
        }
        progressView.layer.backgroundColor = colors.fill.cgColor
        progressView.layer.borderColor = colors.border.cgColor

        primaryLabel.flex.markDirty()
        secondaryLabel.flex.markDirty()
        textContainer.flex.markDirty()
        progressView.flex.markDirty()
        imageHolder.flex.markDirty()
        
        rootFlexContainer.flex.layout()
        rootFlexContainer.flex.markDirty()
    }
    
    private func lastBlockRelativeString() -> String {
        return RelativeFormatter.format(date:lastBlockDate, style:RelativeFormatter.Style(flavours: [.longTime], gradation: RelativeFormatter.Gradation.twitter()), locale:Locale.current)
    }
    
    private func updateLastBlockRelativeString() {
        switch currentDisplayConfiguration {
        case let .syncronized(_, secondaryLocalization):
            secondaryLabel.text = secondaryLocalization + " " + lastBlockRelativeString()
            secondaryLabel.flex.markDirty()
            rootFlexContainer.flex.layout()
        default:
            return
        }
    }
    
    private func launchRelativeDateDisplayTimer() {
        if (timerLaunched == false) {
            Timer.scheduledTimer(withTimeInterval: 2, repeats: true, block: { [weak self] timer in
                guard let self = self else {
                    timer.invalidate()
                    return
                }
                
                guard self.timerLaunched == true else {
                    timer.invalidate()
                    return
                }
                
                if (self.isLastBlockDateVisible) {
                    self.updateLastBlockRelativeString()
                }
            })
            timerLaunched = true
        }
    }

}
