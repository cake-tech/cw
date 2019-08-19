import UIKit
import FlexLayout
import SwiftDate

final class ProgressBar: BaseFlexView {
    let progressView: UIView
    let textContainer: UIView
    let imageHolder: UIImageView
    let syncImage: UIImage
    var primaryLabel: UILabel
    var secondaryLabel: UILabel
    
    public typealias ProgressInformation = (progressed:UInt64, track:UInt64)
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
    
    private var isSyncIndicatorVisible:Bool {
        get {
            return !imageHolder.isHidden
        }
        set {
            imageHolder.isHidden = !newValue
            if imageHolder.isHidden == false {
                animateSyncImage()
            }
        }
    }
    
    public var isLastBlockDateVisible:Bool {
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
                secondaryLabel.text = lastBlockRelativeString()
                secondaryLabel.flex.markDirty()
                rootFlexContainer.flex.layout()
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
        syncImage = UIImage(named: "refresh_icon")!.resized(to: CGSize(width: 12, height: 12))
        primaryLabel = UILabel(text: "SYNCING BLOCKCHAIN")
        secondaryLabel = UILabel(text:"AS OF")
        
        super.init()
    }
    
    override func configureView() {
        super.configureView()
        
        imageHolder.image = syncImage
        primaryLabel.font = applyFont(ofSize: 12)
        primaryLabel.textColor = UIColor.wildDarkBlue
        secondaryLabel.font = applyFont(ofSize:10)
        secondaryLabel.textColor = UIColor.wildDarkBlue
        secondaryLabel.textAlignment = .center
        
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
        textContainer.flex.alignItems(.center).justifyContent(.center).define { flex in
            flex.addItem(primaryLabel).alignSelf(.center).width(100%)
            flex.addItem(secondaryLabel).alignSelf(.center).width(100%)
        }
        
        progressView.flex
            .direction(.row).alignItems(.center).justifyContent(.center)
            .height(42)
            .define { flex in
                flex.addItem(imageHolder).marginRight(7)
                flex.addItem(textContainer).alignItems(.center)
        }
        
        rootFlexContainer.flex
            .alignItems(.center).justifyContent(.center)
            .width(100%)
            .define { flex in
                flex.addItem(progressView).width(200)
        }
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
    
    private func displayConfigurationChanged() {
        switch currentDisplayConfiguration {
        case let .syncronized(primaryLocalized, secondaryLocalizedPrefix):
            progressView.flex.backgroundColor(UIColor.purpley)
            primaryLabel.text = primaryLocalized
            secondaryLabel.text = secondaryLocalizedPrefix + " " + lastBlockRelativeString()
            isLastBlockDateVisible = true
            isSyncIndicatorVisible = false
        case let .error(primaryLocalized):
            progressView.flex.backgroundColor(UIColor.mildPinkish)
            primaryLabel.text = primaryLocalized
            isLastBlockDateVisible = false
            isSyncIndicatorVisible = false
        case let .inProgress(primaryLocalized, secondaryLocalized, progressInformation):
            progressView.flex.backgroundColor(UIColor.syncronizingGray)
            primaryLabel.text = primaryLocalized
            secondaryLabel.text = String(progressInformation.progressed) + " / " + String(progressInformation.track) + secondaryLocalized
            isLastBlockDateVisible = false
            isSyncIndicatorVisible = true
        case let .indeterminantMessage(message):
            progressView.flex.backgroundColor(UIColor.purpleyLight)
            primaryLabel.text = message
            isLastBlockDateVisible = false
            isSyncIndicatorVisible = false
        case let .indeterminantSync(message):
            progressView.flex.backgroundColor(UIColor.purpleyLight)
            primaryLabel.text = message
            isLastBlockDateVisible = false
            isSyncIndicatorVisible = true
            return
        }
    }
    
    private func lastBlockRelativeString() -> String {
        return RelativeFormatter.format(date:lastBlockDate, style:RelativeFormatter.Style(flavours: [.longTime], gradation: RelativeFormatter.Gradation.twitter()), locale:Locale.current)
    }
    
    private func updateLastBlockRelativeString() {
        switch currentDisplayConfiguration {
        case let .syncronized(_, secondaryLocalization):
            secondaryLabel.text = secondaryLocalization + " " + lastBlockRelativeString()
            secondaryLabel.flex.markDirty
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
