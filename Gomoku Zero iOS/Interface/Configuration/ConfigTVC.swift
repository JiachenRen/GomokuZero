//
//  ConfigurationTVC.swift
//  Gomoku Zero iOS
//
//  Created by Jiachen Ren on 12/3/18.
//  Copyright © 2018 Jiachen Ren. All rights reserved.
//

import UIKit

class ConfigTVC: UITableViewController {
    
    var blackConfig: Configuration {
        get {return Configuration.black}
        set {Configuration.black = newValue}
    }
    
    var whiteConfig: Configuration {
        get {return Configuration.white}
        set {Configuration.white = newValue}
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.separatorStyle = .none
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return blackConfig.cellConfigs.count
        case 1: return whiteConfig.cellConfigs.count
        default: return 0
        }
    }

    private func config(for indexPath: IndexPath) -> Configuration {
        return indexPath.section == 0 ? blackConfig : whiteConfig
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let config = self.config(for: indexPath)
        let cellConfig = config.cellConfigs[indexPath.row]
        let gCell = tableView.dequeueReusableCell(withIdentifier: cellConfig.id, for: indexPath)
        guard let cell = gCell as? ConfigCellProtocol else {
            return gCell
        }
        cell.configure(cellConfig)
        return cell as! UITableViewCell
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0: return "Black AI"
        case 1: return "White AI"
        default: return ""
        }
    }
    
    var lastSelected: Piece?
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        lastSelected = indexPath.section == 0 ? .black : .white
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? AlgorithmVC {
            if let segueCell = sender as? SegueCell {
                vc.segueConfig = segueCell.segueConfig
                vc.completion = {[unowned self] in
                    let name = segueCell.segueConfig.subtitle
                    let enabled = self.lastSelected == .black ? self.blackConfig.enabled : self.whiteConfig.enabled
                    let config = Configuration(Algorithm(rawValue: name)!, enabled: enabled)
                    if self.lastSelected == .black {
                        self.blackConfig = config
                    } else {
                        self.whiteConfig = config
                    }
                    self.tableView.reloadData()
                }
            }
        }
    }
    
}
