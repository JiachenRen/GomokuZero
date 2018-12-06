//
//  MenuTableViewController.swift
//  Gomoku Zero iOS
//
//  Created by Jiachen Ren on 12/4/18.
//  Copyright © 2018 Jiachen Ren. All rights reserved.
//

import UIKit

class MenuTVC: UITableViewController {

    enum MenuItem {
        static let all: [MenuItem] = [
            .action(title: "Restart"),
            .submenu(title: "AI Configuration", segueId: "config-segue"),
            .action(title: "Undo"),
            .action(title: "Redo"),
            .submenu(title: "Board", segueId: "board-segue"),
        ]
        case action(title: String)
        case submenu(title: String, segueId: String)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.separatorStyle = .none
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return MenuItem.all.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = MenuItem.all[indexPath.row]
        var id = "", title = ""
        switch item {
        case .action(let t):
            id = "action-cell"
            title = t
        case .submenu(let t, _):
            id = "submenu-cell"
            title = t
        }
        let cell = tableView.dequeueReusableCell(withIdentifier: id, for: indexPath) as! MenuCellProtocol
        cell.title.text = title
        return cell as! UITableViewCell
    }
    
    private func performAction(_ command: String) {
        switch command {
        case "Restart":
            sharedBoard.zeroXzero = false
            
            let zero1 = ZeroPlus()
            zero1.identity = .black
            zero1.visDelegate = sharedBoard.zeroPlus.visDelegate
            
            let zero2 = ZeroPlus()
            zero2.identity = .white
            zero2.visDelegate = sharedBoard.zeroPlus.visDelegate
            
            if blackConfig.enabled {
                zero1.personality = blackConfig.resolvePersonality()
                zero1.strategy = blackConfig.resolveStrategy()
                sharedBoard.zeroPlus = zero1
            }
            
            if whiteConfig.enabled {
                zero2.personality = whiteConfig.resolvePersonality()
                zero2.strategy = whiteConfig.resolveStrategy()
                sharedBoard.zeroPlus2 = zero2
            }
            
            if !blackConfig.enabled && whiteConfig.enabled {
                // Special case, disable default board AI
                sharedBoard.zeroPlus = zero2
                sharedBoard.zeroPlus2 = nil
                sharedBoard.zeroIdentity = .white
            } else {
                sharedBoard.zeroIdentity = .black
            }
            
            if sharedBoard.zeroPlus2 != nil {
                sharedBoard.zeroXzero = true
            }
            
            sharedBoard.restart()
            ContainerVC.sharedInstance?.closeLeft()
        case "Undo": sharedBoard.undo()
        case "Redo": sharedBoard.redo()
        default: break
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch MenuItem.all[indexPath.row] {
        case .action(title: let command):
            performAction(command)
        case .submenu(_, segueId: let id):
            performSegue(withIdentifier: id, sender: nil)
        }
        tableView.deselectRow(at: indexPath, animated: false)
    }
    
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 70
    }

    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
