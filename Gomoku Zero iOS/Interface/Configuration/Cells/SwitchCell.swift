//
//  SwitchCell.swift
//  Gomoku Zero iOS
//
//  Created by Jiachen Ren on 12/3/18.
//  Copyright © 2018 Jiachen Ren. All rights reserved.
//

import UIKit

class SwitchCell: UITableViewCell, CellProtocol {
    
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var `switch`: UISwitch!
    var switchConfig: SwitchConfig?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func configure(_ cellConfig: CellConfig) {
        self.switchConfig = (cellConfig as! SwitchConfig)
    }

}
