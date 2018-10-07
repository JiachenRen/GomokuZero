//
//  ViewController.swift
//  Gomoku Zero
//
//  Created by Jiachen Ren on 10/5/18.
//  Copyright © 2018 Jiachen Ren. All rights reserved.
//

import Cocoa

class ViewController: NSViewController, BoardDelegate, BoardViewDelegate {
    
    
    @IBOutlet weak var boardView: BoardView!
    @IBOutlet weak var boardTextureView: BoardTextureView!
    
    func didMouseUpOn(co: Coordinate) {
        // Transfer the interpreted UI action to model
        board.put(at: co)
    }
    
    func boardDidUpdate(pieces: [[Piece]]) {
        // Transfer the current arrangement of pieces to board view for display
        boardView.pieces = pieces
    }
    
    var delegate: ViewControllerDelegate?
    var board: Board = Board(dimension: 19)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print()
        // Establish delegation with board (Model)
        board.delegate = self
        board.zeroPlus.visDelegate = self // Set this to nil to disable visualization
        
        // Establish delegation with board view (View)
        boardView.delegate = self
    }
    
    override func mouseUp(with event: NSEvent) {
        print(event)
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }

}

protocol ViewControllerDelegate {
    var board: Board {get}
}

extension ViewController: ZeroPlusVisualizationDelegate {
    func activeMapUpdated(activeMap: [[Bool]]?) {
        DispatchQueue.main.async {
            self.boardView.activeMap = activeMap
        }
    }
}
