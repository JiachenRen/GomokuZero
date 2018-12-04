//
//  ToggleCell.swift
//  Gomoku Zero iOS
//
//  Created by Jiachen Ren on 12/4/18.
//  Copyright © 2018 Jiachen Ren. All rights reserved.
//

import UIKit

class ToggleCell: UITableViewCell, CellProtocol {

    @IBOutlet weak var stateLabel: UILabel!
    @IBOutlet weak var title: UILabel!
    var toggleConfig: ToggleConfig!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        if selected {
            stateLabel.isHidden = !stateLabel.isHidden
            toggleConfig.isOn = !stateLabel.isHidden
        }
        // Configure the view for the selected state
    }
    
    func configure(_ cellConfig: CellConfig) {
        toggleConfig = (cellConfig as! ToggleConfig)
        stateLabel.isHidden = !toggleConfig.isOn
        title.text = toggleConfig.title
    }

}
