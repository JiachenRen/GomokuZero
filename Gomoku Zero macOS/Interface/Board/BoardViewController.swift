//
//  ViewController.swift
//  Gomoku Zero
//
//  Created by Jiachen Ren on 10/5/18.
//  Copyright © 2018 Jiachen Ren. All rights reserved.
//

import Cocoa

class BoardViewController: NSViewController, BoardViewDataSource {
    
    @IBOutlet weak var boardView: BoardView!
    @IBOutlet weak var boardTextureView: BoardTextureView!
    
    weak var delegate: ViewControllerDelegate?
    var board: Board = Board(dimension: 15)
    var zeroPlus: ZeroPlus {
        return board.zeroPlus
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print()
        // Establish delegation with board (Model)
        board.delegate = self
        zeroPlus.visDelegate = self // Set this to nil to disable visualization
        
        // Establish delegation with board view (View)
        boardView.delegate = self
        boardView.dataSource = self
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
    
    override func mouseUp(with event: NSEvent) {
        print(event)
    }

}

protocol ViewControllerDelegate: AnyObject {
    var board: Board {get}
}

extension BoardViewController: BoardDelegate {
    func gameHasEnded(winner: Piece, coordinates: [Coordinate], popDialogue: Bool) {
        self.boardView.winningCoordinates = coordinates
        DispatchQueue.main.async {
            if popDialogue {
                let msg = winner == .black ? "Black wins!" : winner == .none ? "Draw!" : "White wins!"
                _  = dialogue(msg: msg, infoTxt: "Hit Shift + Command + R (⇧⌘R) to restart the game.")
            }
        }
    }
    
    func boardDidUpdate(pieces: [[Piece]]) {
        // Transfer the current arrangement of pieces to board view for display
        boardView.updateDisplay()
    }
    
}

extension BoardViewController: BoardViewDelegate {
    func didMouseUpOn(co: Coordinate) {
        // Transfer the interpreted UI action to model
        board.put(at: co)
    }
}

extension BoardViewController: VisualizationDelegate {
    func activeMapUpdated(activeMap: [[Bool]]?) {
        boardView.activeMap = activeMap
    }
    
    func historyDidUpdate(history: History?) {
        boardView.zpHistory = history
    }
}
