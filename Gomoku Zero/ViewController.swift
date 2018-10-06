//
//  ViewController.swift
//  Gomoku Zero
//
//  Created by Jiachen Ren on 10/5/18.
//  Copyright © 2018 Jiachen Ren. All rights reserved.
//

import Cocoa

class ViewController: NSViewController, BoardDelegate {
    
    @IBOutlet weak var boardView: BoardView!
    
    func boardDidUpdate(pieces: [[Piece]]) {
        // Transfer the current arrangement of pieces to board view for display
        boardView.pieces = pieces
    }
    

    var board: Board {
        return Board.sharedInstance
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Establish delegation with board (Model)
        board.delegate = self
        
        // Spawn a few psuedo pieces for testing the UI
        board.spawnPseudoPieces()
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }


}

