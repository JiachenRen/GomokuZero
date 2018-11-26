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
    
    @IBOutlet var tapRecognizer: UITapGestureRecognizer!
    @IBOutlet var doubleTouchRecognizer: UITapGestureRecognizer!
    @IBOutlet var tripleTouchRecognizer: UITapGestureRecognizer!
    
    @IBOutlet var panRecognizer: UIPanGestureRecognizer!
    @IBOutlet var pinchRecognizer: UIPinchGestureRecognizer!
    
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
        tapRecognizer.numberOfTapsRequired = 1
        doubleTouchRecognizer.numberOfTouchesRequired = 2
        tripleTouchRecognizer.numberOfTouchesRequired = 3
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
    
    @IBAction func didPan(_ sender: UIPanGestureRecognizer) {
        let trans = sender.translation(in: nil)
        boardView.frame.origin.translate(by: trans)
        sender.setTranslation(.zero, in: nil)
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
        }
        
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

// MARK: Extensions

extension CGPoint {
    
    static prefix func - (point: CGPoint) -> CGPoint {
        return CGPoint(x: -point.x, y: -point.y)
    }
    
    func translate(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
        return translating(by: .init(x: x, y: y))
    }
    
    mutating func translate(by point: CGPoint) {
        x += point.x
        y += point.y
    }
    
    func translating(by point: CGPoint) -> CGPoint {
        return .init(x: point.x + x, y: point.y + y)
    }
    
    static func midpoint(from p1: CGPoint, to p2: CGPoint) -> CGPoint{
        return CGPoint(x: (p2.x+p1.x)/2, y: (p2.y+p1.y)/2)
    }
    
    static func *(point: CGPoint, scalar: CGFloat) -> CGPoint {
        return CGPoint(x: point.x * scalar, y: point.y * scalar)
    }
    
    static func +(lhs: CGPoint, rhs: CGPoint) -> CGPoint {
        return CGPoint(x: lhs.x + rhs.x, y: lhs.y + rhs.y)
    }
    static func -(lhs: CGPoint, rhs: CGPoint) -> CGPoint {
        return lhs + -rhs
    }
}


