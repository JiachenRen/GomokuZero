//
//  ViewController.swift
//  Gomoku Zero iOS
//
//  Created by Jiachen Ren on 11/25/18.
//  Copyright © 2018 Jiachen Ren. All rights reserved.
//

import UIKit

let sharedBoard = Board(dimension: 15)

class BoardViewController: UIViewController, BoardViewDataSource {
    
    @IBOutlet weak var boardImgView: UIImageView!
    @IBOutlet weak var boardView: BoardView!
    @IBOutlet weak var consoleTextView: UITextView!
    
    @IBOutlet var tapRecognizer: UITapGestureRecognizer!
    @IBOutlet var doubleTouchRecognizer: UITapGestureRecognizer!
    @IBOutlet var tripleTouchRecognizer: UITapGestureRecognizer!
    
    @IBOutlet var panRecognizer: UIPanGestureRecognizer!
    @IBOutlet var pinchRecognizer: UIPinchGestureRecognizer!
    
    static var sharedInstance: BoardViewController?
    weak var delegate: ViewControllerDelegate?
    var lastMove: Move?
    
    var board: Board = sharedBoard
    var zeroPlus: ZeroPlus {
        return board.zeroPlus
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Establish delegation with board (Model)
        board.delegate = self
        zeroPlus.visDelegate = self // Set this to nil to disable visualization
        board.zeroIdentity = .black
        board.requestZeroBrainStorm()
        
        // Establish delegation with board view (View)
        boardView.dataSource = self
        
        // Configure gesture recognizer
        tapRecognizer.numberOfTapsRequired = 1
        doubleTouchRecognizer.numberOfTouchesRequired = 2
        tripleTouchRecognizer.numberOfTouchesRequired = 3
        
        // Add rounded corner to console
        consoleTextView.layer.cornerRadius = 10
        
        // Link shared instance
        BoardViewController.sharedInstance = self
    }
    
    @IBAction func didTap(_ sender: UITapGestureRecognizer) {
        let co = boardView.onBoard(sender.location(in: boardView))
        board.put(at: co)
        
        // Clear console logs
        self.consoleTextView.text = ""
        
        // Prevent the player from making a move when the computer is thinking.
        boardView.isUserInteractionEnabled = false
    }
    
    @IBAction func didPan(_ sender: UIPanGestureRecognizer) {
        let trans = sender.translation(in: nil)
        boardView.frame.origin.translate(by: trans)
        sender.setTranslation(.zero, in: nil)
        
        boardImgView.frame = boardView.frame
    }
    
    @IBAction func didPinch(_ sender: UIPinchGestureRecognizer) {
        let origin = boardView.frame.origin
        let anchor = sender.location(in: nil)
        let scale = sender.scale
        
        // Re-scale the board
        var size = boardView.frame.size
        size.width *= scale
        size.height = size.width
        boardView.frame.size = size
        
        // Translate the board so the zooming appears spot-on
        let escapeDir = (origin - anchor) * scale
        boardView.frame.origin = escapeDir + anchor
        
        // Redraw the view to prevent pixelation when resizing ends
        if sender.state == .ended {
            boardView.setNeedsDisplay()
            boardImgView.setNeedsDisplay()
        }
        
        boardImgView.frame = boardView.frame
        consoleTextView.layoutIfNeeded()
        
        // Reset scaling factor
        sender.scale = 1
    }
    
    @IBAction func didDoubleTouch(_ sender: UITapGestureRecognizer) {
        board.undo()
    }
    
    @IBAction func didTripleTouch(_ sender: UITapGestureRecognizer) {
        board.redo()
    }
    
}

protocol ViewControllerDelegate: AnyObject {
    var board: Board {get}
}

extension BoardViewController: BoardDelegate {
    func gameHasEnded(winner: Piece, coordinates: [Coordinate], popDialogue: Bool) {
        self.boardView.winningCoordinates = coordinates
        let w = winner == .black ? "Black Wins!" : winner == .none ? "Draw!" : "White Wins!"
        alert(title: w)
    }
    
    func boardDidUpdate(pieces: [[Piece]]) {
        
        // Make it so that the user can make their move
        DispatchQueue.main.async {[unowned self] in
            self.boardView.isUserInteractionEnabled = true
            self.boardView.updateDisplay()
        }

    }
    
}

extension BoardViewController: VisualizationDelegate {
    func activeMapUpdated(activeMap: [[Bool]]?) {
        // Do nothing
    }
    
    func historyDidUpdate(history: History?) {
        DispatchQueue.main.async {[unowned self] in
            if self.consoleTextView.isHidden {return}
            self.boardView.zeroPlusHistory = history
            if let idc =  self.board.zeroPlus.cortex as? IterativeDeepeningCortex {
                if let move = idc.bestMove, self.lastMove == nil ||
                    (move.co != self.lastMove!.co || move.score != self.lastMove!.score) {
                    self.lastMove = move
                    
                    let log = "\ttime = \(self.board.zeroPlus.duration) s\n"
                        + "\trow = \(move.co.row), "
                        + "\tcolumn = \(move.co.col)\n"
                        + "\tscore = \(move.score)\n\n"
                    
                    self.consoleTextView.text += log
                }
            }
        }
    }
}
