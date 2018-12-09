//
//  ViewController.swift
//  Gomoku Zero
//
//  Created by Jiachen Ren on 10/5/18.
//  Copyright © 2018 Jiachen Ren. All rights reserved.
//

import Cocoa

class BoardViewController: NSViewController, BoardViewDelegate {
    
    @IBOutlet weak var boardView: BoardView!
    @IBOutlet weak var boardTextureView: BoardTextureView!
    
    weak var delegate: ViewControllerDelegate?
    var board: Board = Board(dimension: 19)
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
    
    func didMouseUpOn(co: Coordinate) {
        // Transfer the interpreted UI action to model
        board.put(at: co)
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
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
        boardView.pieces = pieces
//        DispatchQueue.main.async {[unowned self] in
//            self.boardView.setNeedsDisplay(self.boardView.bounds)
//        }
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
