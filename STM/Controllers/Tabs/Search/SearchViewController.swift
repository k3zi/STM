//
//  SearchViewController.swift
//  STM
//
//  Created by Kesi Maduka on 4/25/16.
//  Copyright © 2016 Storm Edge Apps LLC. All rights reserved.
//

import Foundation

class SearchViewController: KZViewController, UISearchBarDelegate, UIViewControllerPreviewingDelegate {

    let tableView = UITableView()
    let searchBar = UISearchBar()
    var searchResults = [Any]()
    var searchAttempt = 0

    lazy var keynode: Keynode.Connector = Keynode.Connector(view: self.view)
    var tableViewBottomConstraint: NSLayoutConstraint?

    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = "Search"

        searchBar.delegate = self
        view.addSubview(searchBar)

        tableView.delegate = self
        tableView.dataSource = self
        tableView.registerReusableCell(SearchUserCell.self)
        tableView.registerReusableCell(SearchStreamCell)
        view.addSubview(tableView)

        registerForPreviewing(with: self, sourceView: tableView)

        keynode.animationsHandler = { [weak self] show, rect in
            guard let me = self else {
                return
            }

            if let con = me.tableViewBottomConstraint {
                con.constant = (show ? -rect.size.height + 54 + (AppDelegate.del().playerIsMinimized() ? 44 : 0) : 0)
                me.view.layoutIfNeeded()
            }
        }
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        self.view.endEditing(true)
    }

    override func setupConstraints() {
        super.setupConstraints()

        searchBar.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets.zero, excludingEdge: .bottom)

        tableView.autoPinEdge(.top, to: .bottom, of: searchBar)
        tableView.autoPinEdge(toSuperviewEdge: .left)
        tableView.autoPinEdge(toSuperviewEdge: .right)
        tableViewBottomConstraint = tableView.autoPin(toBottomLayoutGuideOf: self, withInset: 0)
    }

    override func tableViewCellData(_ tableView: UITableView, section: Int) -> [Any] {
        return searchResults
    }

    override func tableViewCellClass(_ tableView: UITableView, indexPath: IndexPath?) -> KZTableViewCell.Type {
        if searchResults[indexPath?.row ?? 0] is STMUser {
            return SearchUserCell.self
        } else if searchResults[indexPath?.row ?? 0] is STMStream {
            return SearchStreamCell.self
        }

        return SearchUserCell.self
    }

    override func tableViewNoDataText(_ tableView: UITableView) -> String {
        if let text = searchBar.text {
            if text.characters.count == 0 {
                return "Search for a user or stream using the field above"
            }
        } else {
            return "Search for a user or stream using the field above"
        }

        return super.tableViewNoDataText(tableView)
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        super.tableView(tableView, didSelectRowAt: indexPath)

        guard tableViewCellData(tableView, section: indexPath.section).count > 0 else {
            return
        }

        let model = tableViewCellData(tableView, section: indexPath.section)[indexPath.row]

        if let stream = model as? STMStream {
            let vc = PlayerViewController()
            vc.start(stream, vc: self, showHUD: true, callback: { (success, error) in
                if error == nil {
                    AppDelegate.del().presentStreamController(vc)
                }
            })
        } else if let user = model as? STMUser {
            guard AppDelegate.del().currentUser?.id != user.id else {
                self.navigationController?.tabBarController?.selectedIndex = Constants.UI.Tabs.indexForProfile
                return
            }

            let vc = ProfileViewController(user: user, isOwner: AppDelegate.del().currentUser?.id == user.id)
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }

    // MARK: UISearchBar Delegate

    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        searchBar.setShowsCancelButton(true, animated: true)
    }

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        searchResults = [Any]()
        tableView.reloadData()

        guard let text = searchBar.text else {
            return
        }

        guard text.characters.count > 0 else {
            return
        }

        let attempt = searchAttempt + 1
        searchAttempt = attempt

        Constants.Network.POST("/search", parameters: ["q": text]) { (response, error) in
            self.handleResponse(response as AnyObject?, error: error as NSError?, successCompletion: { (result) in
                if attempt == self.searchAttempt {
                    guard let results = result as? [[String: AnyObject]] else {
                        return
                    }

                    for item in results {
                        if let type = item["_type"] as? String {
                            if type == "STMUser" {
                                if let user = STMUser(json: item) {
                                    self.searchResults.append(user)
                                }
                            } else if type == "STMStream" {
                                if let stream = STMStream(json: item) {
                                    self.searchResults.append(stream)
                                }
                            }
                        }
                    }

                    self.tableView.reloadData()
                }
            })
        }
    }

    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchResults = [Any]()
        searchBar.text = ""
        searchBar.resignFirstResponder()
        searchBar.setShowsCancelButton(false, animated: true)
        tableView.reloadData()
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }

    //MARK: UIViewController Previewing Delegate

    func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        guard let indexPath = tableView.indexPathForRow(at: location), let cell = tableView.cellForRow(at: indexPath) else {
            return nil
        }

        var vc: UIViewController?

        if let stream = searchResults[indexPath.row] as? STMStream {
            guard AppDelegate.del().activeStreamController == nil else {
                return nil
            }

            let pVC = PlayerViewController()
            pVC.isPreviewing = true
            pVC.start(stream, vc: self, showHUD: false)
            vc = pVC
        } else if let user = searchResults[indexPath.row] as? STMUser {
            if AppDelegate.del().currentUser?.id == user.id {
                return nil
            }

            vc = ProfileViewController(user: user)
        }

        if let vc = vc {
            vc.preferredContentSize = CGSize(width: 0.0, height: 0.0)
            previewingContext.sourceRect = cell.frame
        }

        return vc
    }

    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        if let vc = viewControllerToCommit as? PlayerViewController {
            vc.isPreviewing = false
            AppDelegate.del().presentStreamController(vc)
        } else {
            self.navigationController?.pushViewController(viewControllerToCommit, animated: true)
        }
    }

}
