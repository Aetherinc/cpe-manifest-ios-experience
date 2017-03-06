//
//  ExtrasTalentSelectorViewController.swift
//


import UIKit
import AVFoundation
import NextGenDataManager

class ExtrasTalentSelectorViewController: ExtrasExperienceViewController {
    
    @IBOutlet private weak var talentTableView: UITableView!
    @IBOutlet private weak var talentDetailView: UIView!
    
    private var talentDetailViewController: TalentDetailViewController?
    fileprivate var selectedIndexPath: IndexPath?
    
    // MARK: View Lifecycle
    override func viewDidLoad() {
        customTitle = String.localize("label.actors")
        
        super.viewDidLoad()
        
        talentTableView.register(UINib(nibName: "TalentTableViewCell-Narrow" + (DeviceType.IS_IPAD ? "" : "_iPhone"), bundle: nil), forCellReuseIdentifier: TalentTableViewCell.ReuseIdentifier)
        
        showBackButton()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if selectedIndexPath == nil {
            let path = IndexPath(row: 0, section: 0)
            self.talentTableView.selectRow(at: path, animated: false, scrollPosition: .top)
            self.tableView(self.talentTableView, didSelectRowAt: path)
        }
    }
    
    // MARK: Talent Details
    fileprivate func showTalentDetailView() {
        if selectedIndexPath != nil, let talent = (talentTableView?.cellForRow(at: selectedIndexPath!) as? TalentTableViewCell)?.talent, let talentDetailViewController = UIStoryboard.getNextGenViewController(TalentDetailViewController.self) as? TalentDetailViewController {
            talentDetailViewController.talent = talent
            
            talentDetailViewController.view.frame = talentDetailView.bounds
            talentDetailView.addSubview(talentDetailViewController.view)
            self.addChildViewController(talentDetailViewController)
            talentDetailViewController.didMove(toParentViewController: self)
            
            showBackButton()
            
            if talentDetailView.isHidden {
                talentDetailView.alpha = 0
                talentDetailView.isHidden = false
                UIView.animate(withDuration: 0.25, animations: {
                    self.talentDetailView.alpha = 1
                })
            } else {
                talentDetailViewController.view.alpha = 0
                UIView.animate(withDuration: 0.25, animations: {
                    talentDetailViewController.view.alpha = 1
                })
            }
            
            self.talentDetailViewController = talentDetailViewController
            NextGenHook.logAnalyticsEvent(.extrasAction, action: .selectTalent, itemId: talent.id)
        }
    }
    
    fileprivate func hideTalentDetailView(completed: (() -> Void)? = nil) {
        if talentDetailViewController != nil {
            if selectedIndexPath != nil {
                talentTableView?.deselectRow(at: selectedIndexPath!, animated: true)
                selectedIndexPath = nil
            }
            
            if completed == nil {
                showHomeButton()
            }
            
            UIView.animate(withDuration: 0.25, animations: {
                if completed != nil {
                    self.talentDetailViewController?.view.alpha = 0
                } else {
                    self.talentDetailView?.alpha = 0
                }
            }, completion: { (Bool) -> Void in
                if completed == nil {
                    self.talentDetailView?.isHidden = true
                }
                
                self.talentDetailViewController?.willMove(toParentViewController: nil)
                self.talentDetailViewController?.view.removeFromSuperview()
                self.talentDetailViewController?.removeFromParentViewController()
                self.talentDetailViewController = nil
                completed?()
            })
        } else {
            completed?()
        }
    }
    
}

extension ExtrasTalentSelectorViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return NGDMManifest.sharedInstance.mainExperience?.orderedActors?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: TalentTableViewCell.ReuseIdentifier) as! TalentTableViewCell
        cell.talent = NGDMManifest.sharedInstance.mainExperience?.orderedActors?[indexPath.row]
        
        return cell
    }
    
}

extension ExtrasTalentSelectorViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        return (indexPath != selectedIndexPath ? indexPath : nil)
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        hideTalentDetailView { [weak self] in
            self?.selectedIndexPath = indexPath
            self?.showTalentDetailView()
        }
    }
    
}

extension ExtrasTalentSelectorViewController: TalentDetailViewPresenter {
    
    func talentDetailViewShouldClose() {
        hideTalentDetailView()
    }
    
}
