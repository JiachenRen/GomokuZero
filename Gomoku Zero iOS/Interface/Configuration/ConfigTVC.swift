//
//  ConfigurationTVC.swift
//  Gomoku Zero iOS
//
//  Created by Jiachen Ren on 12/3/18.
//  Copyright © 2018 Jiachen Ren. All rights reserved.
//

import UIKit

class ConfigTVC: UITableViewController {

    
    var blackConfig = Configuration(.zeroMax)
    var whiteConfig = Configuration(.zeroMax)
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
        
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
        guard let cell = gCell as? CellProtocol else {
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
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
    }
    
    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? AlgorithmVC {
            if let segueCell = sender as? SegueCell {
                vc.segueConfig = segueCell.segueConfig
                vc.completion = {[unowned self] in
                    let name = segueCell.segueConfig.subtitle
                    let isBlack = self.blackConfig.cellConfigs.contains{segueCell.segueConfig === $0}
                    let config = Configuration(Algorithm(rawValue: name)!)
                    if isBlack {self.blackConfig = config}
                    else {self.whiteConfig = config}
                    self.tableView.reloadData()
                }
            }
        }
    }
    

}

class Configuration {
    var algorithm: Algorithm {
        let config = cellConfigs[0] as! SegueConfig
        return Algorithm(rawValue: config.subtitle)!
    }
    var cellConfigs: [CellConfig]
    
    init(_ algorithm: Algorithm) {
        let idx = Algorithm.all.firstIndex(of: algorithm)!
        
        cellConfigs = [
            SegueConfig(title: "Algorithm",
                        selectedIdx: idx,
                        subtitles: Algorithm.all.map{$0.rawValue})
        ]
        cellConfigs.append(contentsOf: configs[algorithm]!)
    }
}

enum Algorithm: String {
    static let all: [Algorithm] = [.heuristic, .zeroSum, .minimax, .negaScout, .monteCarlo, .zeroMax]
    
    case heuristic = "Heuristic"
    case zeroSum = "Zero Sum"
    case minimax = "Minimax"
    case negaScout = "NegaScout (PVS)"
    case monteCarlo = "MCTS"
    case zeroMax = "Zero Max"
}

// Default configuration for all algorithms.
let configs: [Algorithm: [CellConfig]] = [
    .heuristic: [
        ToggleConfig(title: "Randomized Selection", isOn: true)
    ],
    .zeroSum: [
        ToggleConfig(title: "Randomized Selection", isOn: true)
    ],
    .minimax: [
        ToggleConfig(title: "Randomized Selection", isOn: true),
        StepperConfig(title: "Timeout (s)", min: 1, max: 60, val: 15),
        StepperConfig(title: "Depth", min: 0, max: 10, val: 4),
        StepperConfig(title: "Breadth", min: 1, max: 20, val: 6),
        ToggleConfig(title: "Iterative Deepening", isOn: true),
        SegmentedConfig(title: "Layers", selectedIdx: 1, subtitles: ["All", "Even", "Odd"]),
    ],
    .negaScout: [
        ToggleConfig(title: "Randomized Selection", isOn: true),
        StepperConfig(title: "Timeout (s)", min: 1, max: 60, val: 15),
        StepperConfig(title: "Depth", min: 0, max: 10, val: 4),
        StepperConfig(title: "Breadth", min: 1, max: 20, val: 6),
        ToggleConfig(title: "Iterative Deepening", isOn: true),
        SegmentedConfig(title: "Layers", selectedIdx: 1, subtitles: ["All", "Even", "Odd"]),
    ],
    .monteCarlo: [
        ToggleConfig(title: "Randomized Expansion", isOn: true),
        StepperConfig(title: "Timeout (s)", min: 1, max: 60, val: 3),
        StepperConfig(title: "Sim. Depth", min: 1, max: 20, val: 6),
        StepperConfig(title: "Breadth", min: 1, max: 20, val: 10),
    ],
    .zeroMax: [
        ToggleConfig(title: "Randomized Selection", isOn: true),
        StepperConfig(title: "Timeout (s)", min: 1, max: 60, val: 15),
        StepperConfig(title: "Depth", min: 0, max: 10, val: 2),
        StepperConfig(title: "Ext. Depth", min: 0, max: 20, val: 8),
        StepperConfig(title: "Breadth", min: 1, max: 20, val: 10),
        StepperConfig(title: "Ext. Pr.", min: 1, max: 100, val: 100),
        ToggleConfig(title: "Iterative Deepening", isOn: true),
        SegmentedConfig(title: "Layers", selectedIdx: 0, subtitles: ["All", "Even", "Odd"]),
    ]
]
