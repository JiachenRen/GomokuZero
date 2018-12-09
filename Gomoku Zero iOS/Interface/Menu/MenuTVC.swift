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
        case action(title: String, handler: () -> Void)
        case submenu(title: String, segueId: String)
    }
    
    let menuItems: [MenuItem] = [
        .action(title: "Restart") {
            Configuration.apply()
            sharedBoard.restart()
            ContainerVC.sharedInstance?.closeLeft()
        },
        .submenu(title: "AI Configuration", segueId: "config-segue"),
        .action(title: "Undo", handler: sharedBoard.undo),
        .action(title: "Redo", handler: sharedBoard.redo),
        .submenu(title: "Board", segueId: "board-segue"),
        .action(title: "Save", handler: save)
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.separatorStyle = .none
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return menuItems.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = menuItems[indexPath.row]
        var id = "", title = ""
        switch item {
        case .action(let t, _):
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
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch menuItems[indexPath.row] {
        case .action(_, let handler): handler()
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

func save() {
    if sharedBoard.history.stack.count == 0 {
        ContainerVC.sharedInstance?.alert(title: "Can't Save", msg: "Give me some juice!")
        return
    }
    
    let alert = UIAlertController(title: "Enter File Name", message: nil, preferredStyle: .alert)
    
    alert.addTextField { (textField) in
        textField.text = "Saved Game"
    }
    
    alert.addAction(UIAlertAction(title: "Save", style: .default) {_ in
        Game.save(sharedBoard, name: alert.textFields![0].text!)
    })
    
    alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
    
    ContainerVC.sharedInstance?.closeLeft()
    ContainerVC.sharedInstance?.present(alert, animated: true, completion: nil)
}
