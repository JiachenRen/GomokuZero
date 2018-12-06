//
//  Cell.swift
//  Gomoku Zero iOS
//
//  Created by Jiachen Ren on 12/4/18.
//  Copyright © 2018 Jiachen Ren. All rights reserved.
//

import Foundation
import UIKit

class CellConfig {
    var id: String {
        return ""
    }
    var title: String
    
    
    init(title: String) {
        self.title = title
    }
}

class SwitchConfig: CellConfig {
    override var id: String {
        return "switch-cell"
    }
    
    var isOn: Bool
    var handler: ((Bool) -> Void)?
    
    init(title: String, isOn: Bool, handler: ((Bool) -> Void)? = nil) {
        self.isOn = isOn
        self.handler = handler
        super.init(title: title)
    }
}

class SegueConfig: CellConfig {
    override var id: String {
        return "segue-cell"
    }
    
    var subtitles: [String]
    var selectedIdx: Int
    var subtitle: String {
        return subtitles[selectedIdx]
    }
    var handler: (() -> Void)?
    
    init(title: String, selectedIdx: Int, subtitles: [String], handler: (() -> Void)? = nil) {
        self.selectedIdx = selectedIdx
        self.subtitles = subtitles
        self.handler = handler
        super.init(title: title)
    }
}

class StepperConfig: CellConfig {
    override var id: String {
        return "stepper-cell"
    }
    
    var min: Double
    var max: Double
    var val: Double
    var handler: ((Int) -> Void)?
    
    init(title: String, min: Double, max: Double, val: Double, handler: ((Int) -> Void)? = nil) {
        self.min = min
        self.max = max
        self.val = val
        self.handler = handler
        super.init(title: title)
    }
}

class SegmentedConfig: SegueConfig {
    override var id: String {
        return "segmented-cell"
    }
}

class ToggleConfig: SwitchConfig {
    override var id: String {
        return "toggle-cell"
    }
}


