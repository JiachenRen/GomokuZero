//
//  CellProtocol.swift
//  Gomoku Zero iOS
//
//  Created by Jiachen Ren on 12/4/18.
//  Copyright © 2018 Jiachen Ren. All rights reserved.
//

import Foundation
import UIKit
protocol ConfigCellProtocol {
    var title: UILabel! {get}
    func configure(_ cellConfig: CellConfig)
}
