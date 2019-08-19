import UIKit
import FlexLayout
import SwiftDate

final class ProgressBar: BaseFlexView {
    let progressView: UIView
    let textContainer: UIView
    let imageHolder: UIImageView
    let syncImage: UIImage
    var statusLabel: UILabel
    var asOfLabel: UILabel
    
    public typealias ProgressConfiguration = (part:UInt64, track:UInt64)
    public typealias StaticConfiguration = (primary:String, secondary:String)
    public enum ProgressBarDisplayConfiguration {
        case syncronized(String, String)
        case inProgress(ProgressConfiguration)
        case indeterminant(StaticConfiguration)
        case error(StaticConfiguration)
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
            return !asOfLabel.isHidden
        }
        set {
            if (newValue == false) {
                asOfLabel.isHidden = true
                asOfLabel.text = ""
                asOfLabel.flex.markDirty()
                rootFlexContainer.flex.layout()
            } else {
                asOfLabel.isHidden = false
                asOfLabel.text = lastBlockRelativeString()
                asOfLabel.flex.markDirty()
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
    private var _datePrefix = ""
    public var lastBlockDatePrefix:String {
        set {
            _datePrefix = newValue
            updateLastBlockRelativeString()
        }
        get {
            return _datePrefix
        }
    }
    private var timerLaunched = false
    
    required init() {
        progressView = UIView()
        textContainer = UIView()
        imageHolder = UIImageView()
        syncImage = UIImage(named: "refresh_icon")!.resized(to: CGSize(width: 12, height: 12))
        statusLabel = UILabel(text: "SYNCING BLOCKCHAIN")
        asOfLabel = UILabel(text:"AS OF")
        
        super.init()
    }
    
    override func configureView() {
        super.configureView()
        
        imageHolder.image = syncImage
        statusLabel.font = applyFont(ofSize: 12)
        statusLabel.textColor = UIColor.wildDarkBlue
        asOfLabel.font = applyFont(ofSize:10)
        asOfLabel.textColor = UIColor.wildDarkBlue
        asOfLabel.textAlignment = .center
        
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
            flex.addItem(statusLabel).alignSelf(.center).width(100%)
            flex.addItem(asOfLabel).alignSelf(.center).width(100%)
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
    
    func animateSyncImage() {
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
        case let .syncronized(localization):
            progressView.flex.backgroundColor(UIColor.purpley)
            isSyncIndicatorVisible = false
            statusLabel.text = localization
            
        default:
            return
        }
    }
    
    private func lastBlockRelativeString() -> String {
        if (_datePrefix.count == 0) {
            return RelativeFormatter.format(date:lastBlockDate, style:RelativeFormatter.Style(flavours: [.longTime], gradation: RelativeFormatter.Gradation.twitter()), locale:Locale.current)
        } else {
            return _datePrefix + " " + RelativeFormatter.format(date:lastBlockDate, style:RelativeFormatter.Style(flavours: [.longTime], gradation: RelativeFormatter.Gradation.twitter()), locale:Locale.current)
        }
        
    }
    
    private func updateLastBlockRelativeString() {
        if (isLastBlockDateVisible) {
            asOfLabel.text = lastBlockRelativeString()
        } else {
            asOfLabel.text = ""
        }
        asOfLabel.flex.markDirty()
        rootFlexContainer.flex.layout()
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
