//
//  ViewController.swift
//  Gomoku Zero iOS
//
//  Created by Jiachen Ren on 11/25/18.
//  Copyright © 2018 Jiachen Ren. All rights reserved.
//

import UIKit

class BoardViewController: UIViewController, BoardViewDelegate {
    
    
    @IBOutlet weak var boardView: BoardView!
    @IBOutlet var tapGestureRecognizer: UITapGestureRecognizer!
    
    var delegate: ViewControllerDelegate?
    
    var board: Board = Board(dimension: 19)
    var zeroPlus: ZeroPlus {
        return board.zeroPlus
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Establish delegation with board (Model)
        board.delegate = self
        zeroPlus.visDelegate = self // Set this to nil to disable visualization
        board.zeroIdentity = .black
        
        // Establish delegation with board view (View)
        boardView.delegate = self
        
        // Configure gesture recognizer
        tapGestureRecognizer.numberOfTapsRequired = 1
    }
    
    func updateVisPref(_ name: String) {
        switch name {
        case "Toggle Animation":
            let state = boardView.visualizationEnabled
            boardView.visualizationEnabled = !state
            zeroPlus.visDelegate = state ? nil : self
        case "Toggle Active Map": boardView.activeMapVisible = !boardView.activeMapVisible
        case "Toggle History Stack": boardView.historyVisible  = !boardView.historyVisible
        default: break
        }
    }
    
    @IBAction func didTap(_ sender: UITapGestureRecognizer) {
        let co = boardView.onBoard(sender.location(in: boardView))
        board.put(at: co)
    }
}

protocol ViewControllerDelegate {
    var board: Board {get}
}

extension BoardViewController: BoardDelegate {
    func gameHasEnded(winner: Piece, coordinates: [Coordinate], popDialogue: Bool) {
        self.boardView.winningCoordinates = coordinates
    }
    
    func boardDidUpdate(pieces: [[Piece]]) {
        // Transfer the current arrangement of pieces to board view for display
        boardView.pieces = pieces
    }
    
}

extension BoardViewController: VisualizationDelegate {
    func activeMapUpdated(activeMap: [[Bool]]?) {
        DispatchQueue.main.async {
            self.boardView.activeMap = activeMap
        }
    }
    
    func historyDidUpdate(history: History?) {
        DispatchQueue.main.async {
            self.boardView.zeroPlusHistory = history
        }
    }
}
