//
//  BrowseCell.swift
//  Gomoku Zero iOS
//
//  Created by Jiachen Ren on 12/9/18.
//  Copyright © 2018 Jiachen Ren. All rights reserved.
//

import UIKit

class BrowseCell: UICollectionViewCell, BoardViewDataSource {
    @IBOutlet weak var boardView: BoardView!
    @IBOutlet weak var nameLabel: UILabel!
    var board: Board = Board(dimension: 15)
    
    func configure(_ game: Game) {
        nameLabel.text = game.name ?? "Saved Game"
        boardView.dataSource = self
        nameLabel.layer.cornerRadius = 5
        if let data = game.data {
            board.load(data)
        }
    }
    
}
