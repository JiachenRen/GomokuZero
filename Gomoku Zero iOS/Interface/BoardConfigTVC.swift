//
//  ViewTVC.swift
//  Gomoku Zero iOS
//
//  Created by Jiachen Ren on 12/5/18.
//  Copyright © 2018 Jiachen Ren. All rights reserved.
//

import UIKit

class BoardConfigTVC: UITableViewController {
    
    var boardVC: BoardViewController {
        return (navigationController!.parent! as! ContainerVC).mainViewController! as! BoardViewController
    }

    var cellConfigs = [CellConfig]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.separatorStyle = .none
        
        cellConfigs = [
            SwitchConfig(title: "Animation", isOn: boardVC.boardView.visualizationEnabled) {
                [unowned self] enabled in
                let vc = self.boardVC
                vc.boardView.visualizationEnabled = enabled
                vc.boardView.activeMapVisible = false
                vc.boardView.historyVisible = true // Only show history stack for mobile version.
                sharedBoard.zeroPlus.visDelegate = enabled ? vc : nil
                sharedBoard.zeroPlus2?.visDelegate = enabled ? vc : nil
            },
            SwitchConfig(title: "Step Number", isOn: boardVC.boardView.overlayStepNumber) {
                [unowned self] enabled in
                let boardView = self.boardVC.boardView
                boardView?.overlayStepNumber = enabled
            },
            SwitchConfig(title: "Calc. Duration", isOn: boardVC.boardView.showCalcDuration) {
                [unowned self] enabled in
                let boardView = self.boardVC.boardView
                boardView?.showCalcDuration = enabled
                if enabled {
                    sharedBoard.zeroPlus.visDelegate = self.boardVC
                    sharedBoard.zeroPlus2?.visDelegate = self.boardVC
                }
            },
            StepperConfig(title: "Dimension", min: 5, max: 19, val: Double(sharedBoard.dimension)) {
                sharedBoard.dimension = Int($0)
            }
        ]
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return cellConfigs.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellConfig = cellConfigs[indexPath.row]
        let gCell = tableView.dequeueReusableCell(withIdentifier: cellConfig.id, for: indexPath)
        guard let cell = gCell as? ConfigCellProtocol else {
            return gCell
        }
        cell.configure(cellConfig)
        cell.title.text = cellConfig.title
        return cell as! UITableViewCell
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
