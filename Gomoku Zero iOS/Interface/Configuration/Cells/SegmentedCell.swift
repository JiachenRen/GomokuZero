//
//  SegmentedCell.swift
//  Gomoku Zero iOS
//
//  Created by Jiachen Ren on 12/4/18.
//  Copyright © 2018 Jiachen Ren. All rights reserved.
//

import UIKit

class SegmentedCell: UITableViewCell, ConfigCellProtocol {

    
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    @IBOutlet weak var title: UILabel!
    var segmentedConfig: SegmentedConfig!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    @IBAction func segmentedControlValueChanged(_ sender: UISegmentedControl) {
        segmentedConfig.selectedIdx = sender.selectedSegmentIndex
    }
    
    
    func configure(_ cellConfig: CellConfig) {
        segmentedConfig = (cellConfig as! SegmentedConfig)
        title.text = segmentedConfig.title
        segmentedControl.removeAllSegments()
        segmentedConfig.subtitles.reversed().forEach {
            segmentedControl.insertSegment(withTitle: $0, at: 0, animated: false)
        }
        segmentedControl.selectedSegmentIndex = segmentedConfig.selectedIdx
    }

}
