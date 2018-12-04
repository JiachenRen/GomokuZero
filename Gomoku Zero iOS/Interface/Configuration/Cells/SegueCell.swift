//
//  SegueCell.swift
//  Gomoku Zero iOS
//
//  Created by Jiachen Ren on 12/4/18.
//  Copyright © 2018 Jiachen Ren. All rights reserved.
//

import UIKit

class SegueCell: UITableViewCell, CellProtocol {

    @IBOutlet weak var title: UILabel!
    @IBOutlet weak var subtitle: UILabel!
    var segueConfig: SegueConfig!
    var segue: UIStoryboardSegue?
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        if selected {
            segue?.perform()
        }
        // Configure the view for the selected state
    }
    
    func configure(_ cellConfig: CellConfig) {
        segueConfig = (cellConfig as! SegueConfig)
        title.text = segueConfig.title
        subtitle.text = segueConfig.subtitle
    }

}
