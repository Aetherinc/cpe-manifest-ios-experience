//
//  InMovieExperienceViewController.swift
//

import UIKit

class InMovieExperienceViewController: UIViewController {
    
    struct SegueIdentifier {
        static let PlayerViewController = "PlayerViewControllerSegue"
    }
    
    @IBOutlet weak var playerContainerView: UIView!
    @IBOutlet weak var extrasContainerView: UIView!
    @IBOutlet var playerToExtrasConstarint: NSLayoutConstraint!
    @IBOutlet var playerToSuperviewConstraint: NSLayoutConstraint!
    
    private var externalPlaybackDidToggleObserver: NSObjectProtocol?
    
    private var videoPlayerViewController: VideoPlayerViewController? {
        for viewController in self.childViewControllers {
            if let videoPlayerViewController = viewController as? VideoPlayerViewController {
                return videoPlayerViewController
            }
        }
        
        return nil
    }
    
    private var playbackPercentage: Double? {
        if let videoPlayerViewController = videoPlayerViewController {
            let currentTime = videoPlayerViewController.currentTime
            let duration = videoPlayerViewController.playerItemDuration
            return ((currentTime / duration) * 100)
        }
        
        return nil
    }
    
    private var extrasContainerViewHidden: Bool = false {
        didSet {
            extrasContainerView.isHidden = extrasContainerViewHidden
            for viewController in self.childViewControllers {
                if let viewController = (viewController as? UINavigationController)?.viewControllers.first as? InMovieExperienceExtrasViewController {
                    viewController.view.isHidden = extrasContainerView.isHidden
                    return
                }
            }
        }
    }
    
    deinit {
        if let observer = externalPlaybackDidToggleObserver {
            NotificationCenter.default.removeObserver(observer)
            externalPlaybackDidToggleObserver = nil
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        externalPlaybackDidToggleObserver = NotificationCenter.default.addObserver(forName: .externalPlaybackDidToggle, object: nil, queue: OperationQueue.main, using: { (_) in
            if ExternalPlaybackManager.isExternalPlaybackActive {
                UIDevice.current.setValue(UIInterfaceOrientation.portrait.rawValue, forKey: "orientation")
            }
        })
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        extrasContainerViewHidden = UIInterfaceOrientationIsLandscape(UIApplication.shared.statusBarOrientation)
        updatePlayerConstraints()
    }
    
    private func updatePlayerConstraints() {
        playerToExtrasConstarint.isActive = !extrasContainerView.isHidden
        playerToSuperviewConstraint.isActive = !playerToExtrasConstarint.isActive
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if ExternalPlaybackManager.isExternalPlaybackActive {
            return [.portrait, .portraitUpsideDown]
        }
        
        return .all
    }
    
    override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        if ExternalPlaybackManager.isExternalPlaybackActive {
            return .portrait
        }
        
        return super.preferredInterfaceOrientationForPresentation
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        extrasContainerViewHidden = size.width > size.height
        updatePlayerConstraints()
        
        if let videoPlayerViewController = videoPlayerViewController {
            if extrasContainerView.isHidden {
                NotificationCenter.default.post(name: .inMovieExperienceShouldCloseDetails, object: nil)
            } else if videoPlayerViewController.didPlayInterstitial {
                NotificationCenter.default.post(name: .videoPlayerDidChangeTime, object: nil, userInfo: [NotificationConstants.time: videoPlayerViewController.currentTime])
            }
            
            var timecodeLabel: String?
            if videoPlayerViewController.didPlayInterstitial {
                if let playbackPercentage = playbackPercentage {
                    let roundedPlaybackPercentage = (Int((playbackPercentage + 2.5) / 5) * 5)
                    timecodeLabel = String(roundedPlaybackPercentage) + "%"
                }
            } else {
                timecodeLabel = "interstitial"
            }
            
            NextGenHook.logAnalyticsEvent(.imeAction, action: (extrasContainerView.isHidden ? .rotateHideExtras : .rotateShowExtras), itemName: timecodeLabel)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == SegueIdentifier.PlayerViewController, let playerViewController = segue.destination as? VideoPlayerViewController {
            playerViewController.mode = VideoPlayerMode.mainFeature
        }
    }

}
