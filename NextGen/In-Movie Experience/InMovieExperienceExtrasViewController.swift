//
//  InMovieExperienceViewController.swift
//

import UIKit
import NextGenDataManager

class InMovieExperienceExtrasViewController: UIViewController {
    
    fileprivate struct Constants {
        static let HeaderHeight: CGFloat = 35
        static let FooterHeight: CGFloat = 50
    }
    
    fileprivate struct SegueIdentifier {
        static let ShowTalent = "ShowTalentSegueIdentifier"
    }
    
    @IBOutlet weak private var talentTableView: UITableView?
    @IBOutlet weak private var backgroundImageView: UIImageView!
    @IBOutlet weak private var showLessContainer: UIView!
    @IBOutlet weak private var showLessButton: UIButton!
    @IBOutlet weak private var showLessGradientView: UIView!
    private var showLessGradient = CAGradientLayer()
    fileprivate var currentTalents = [NGDMTalent]()
    private var hiddenTalents: [NGDMTalent]?
    fileprivate var isShowingMore = false
    
    private var currentTime: Double = -1
    private var didChangeTimeObserver: NSObjectProtocol?
    
    deinit {
        if let observer = didChangeTimeObserver {
            NotificationCenter.default.removeObserver(observer)
            didChangeTimeObserver = nil
        }
    }

    // MARK: View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let nodeStyle = NGDMManifest.sharedInstance.inMovieExperience?.getNodeStyle(UIApplication.shared.statusBarOrientation) {
            self.view.backgroundColor = nodeStyle.backgroundColor
            
            if let backgroundImageURL = nodeStyle.backgroundImageURL {
                backgroundImageView.sd_setImage(with: backgroundImageURL)
                backgroundImageView.contentMode = nodeStyle.backgroundScaleMethod == .bestFit ? .scaleAspectFill : .scaleAspectFit
            }
        }
        
        if let actors = NGDMManifest.sharedInstance.mainExperience?.orderedActors , actors.count > 0 {
            talentTableView?.register(UINib(nibName: "TalentTableViewCell-Narrow" + (DeviceType.IS_IPAD ? "" : "_iPhone"), bundle: nil), forCellReuseIdentifier: TalentTableViewCell.ReuseIdentifier)
        } else {
            talentTableView?.removeFromSuperview()
            talentTableView = nil
        }
        
        showLessGradient.colors = [UIColor.clear.cgColor, UIColor.black.cgColor]
        showLessGradientView.layer.insertSublayer(showLessGradient, at: 0)
        
        showLessButton.setTitle(String.localize("talent.show_less"), for: .normal)
        
        didChangeTimeObserver = NotificationCenter.default.addObserver(forName: .videoPlayerDidChangeTime, object: nil, queue: nil) { [weak self] (notification) -> Void in
            if let strongSelf = self, let time = notification.userInfo?[NotificationConstants.time] as? Double, time != strongSelf.currentTime {
                strongSelf.processTimedEvents(time)
            }
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if let talentTableView = talentTableView {
            showLessGradientView.frame.size.width = talentTableView.frame.width
        }
        
        showLessGradient.frame = showLessGradientView.bounds
    }
    
    private func processTimedEvents(_ time: Double) {
        if !self.view.isHidden {
            DispatchQueue.global(qos: .userInteractive).async {
                self.currentTime = time
                
                let newTalents = NGDMTimedEvent.findByTimecode(time, type: .talent).sorted(by: { (timedEvent1, timedEvent2) -> Bool in
                    return timedEvent1.talent!.billingBlockOrder < timedEvent2.talent!.billingBlockOrder
                }).map({ $0.talent! })
                
                if self.isShowingMore {
                    self.hiddenTalents = newTalents
                } else {
                    if (newTalents.count != self.currentTalents.count || newTalents.contains(where: { !self.currentTalents.contains($0) })) {
                        DispatchQueue.main.async {
                            self.currentTalents = newTalents
                            self.talentTableView?.reloadData()
                        }
                    }
                }
            }
        }
    }
    
    // MARK: Actions
    @objc fileprivate func onTapFooter() {
        toggleShowMore()
    }
    
    @IBAction private func onTapShowLess() {
        toggleShowMore()
    }
    
    private func toggleShowMore() {
        isShowingMore = !isShowingMore
        showLessContainer.isHidden = !isShowingMore
        
        if isShowingMore {
            hiddenTalents = currentTalents
            currentTalents = NGDMManifest.sharedInstance.mainExperience?.orderedActors ?? [NGDMTalent]()
            NextGenHook.logAnalyticsEvent(.imeTalentAction, action: .showMore)
        } else {
            currentTalents = hiddenTalents ?? [NGDMTalent]()
            NextGenHook.logAnalyticsEvent(.imeTalentAction, action: .showLess)
        }
        
        talentTableView?.contentOffset = CGPoint.zero
        talentTableView?.reloadData()
    }
    
    // MARK: Storyboard Methods
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == SegueIdentifier.ShowTalent {
            let talentDetailViewController = segue.destination as! TalentDetailViewController
            talentDetailViewController.title = String.localize("talentdetail.title")
            talentDetailViewController.talent = sender as! NGDMTalent
            talentDetailViewController.mode = TalentDetailMode.Synced
        }
    }

}

extension InMovieExperienceExtrasViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return currentTalents.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: TalentTableViewCell.ReuseIdentifier) as! TalentTableViewCell
        if currentTalents.count > indexPath.row {
            cell.talent = currentTalents[indexPath.row]
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return String.localize("label.actors").uppercased()
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return Constants.HeaderHeight
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return Constants.FooterHeight
    }
    
    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        return (isShowingMore ? nil : String.localize("talent.show_more"))
    }
    
}

extension InMovieExperienceExtrasViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        if let header = view as? UITableViewHeaderFooterView {
            header.textLabel?.textAlignment = .center
            header.textLabel?.font = UIFont.themeCondensedFont(DeviceType.IS_IPAD ? 19 : 17)
            header.textLabel?.textColor = UIColor(netHex: 0xe5e5e5)
        }
    }
    
    func tableView(_ tableView: UITableView, willDisplayFooterView view: UIView, forSection section: Int) {
        if let footer = view as? UITableViewHeaderFooterView {
            footer.textLabel?.textAlignment = .center
            footer.textLabel?.font = UIFont.themeCondensedFont(DeviceType.IS_IPAD ? 19 : 17)
            footer.textLabel?.textColor = UIColor(netHex: 0xe5e5e5)
            
            if footer.gestureRecognizers == nil || footer.gestureRecognizers!.count == 0 {
                footer.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.onTapFooter)))
            }
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let cell = tableView.cellForRow(at: indexPath) as? TalentTableViewCell, let talent = cell.talent {
            self.performSegue(withIdentifier: SegueIdentifier.ShowTalent, sender: talent)
            NextGenHook.logAnalyticsEvent(.imeTalentAction, action: .selectTalent, itemId: talent.id)
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
}
