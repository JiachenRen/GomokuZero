//
//  Board.swift
//  Gomoku Zero
//
//  Created by Jiachen Ren on 10/5/18.
//  Copyright © 2018 Jiachen Ren. All rights reserved.
//

import Foundation

class Board: ZeroPlusDelegate, HeuristicEvaluatorDelegate {
    var dimension: Int {
        didSet {
            if dimension != oldValue {
                restart()
            }
        }
    }
    
    // The arrangement of pieces on the board. A 2D array.
    var pieces = [[Piece]]()
    var delegate: BoardDelegate?
    var history = History()
    var heuristicEvaluator: HeuristicEvaluator
    
    var curPlayer: Piece = .black
    var zeroAi: Piece = .none
    var zeroPlus = ZeroPlus()
    var zeroXzero = false // When this is set to true, zero will play against itself!
    var gameHasEnded = false
    let zeroActivityQueue = DispatchQueue(label: "zeroPlus", attributes: .concurrent)
    
    init(dimension: Int) {
        heuristicEvaluator = HeuristicEvaluator()
        self.dimension = dimension
        heuristicEvaluator.delegate = self
        zeroPlus.delegate = self
        restart()
    }
    
    func clear() {
        pieces = [[Piece]](repeating: Array(repeatElement(Piece.none, count: dimension)), count: dimension)
    }
    
    func restart() {
        clear()
        curPlayer = .black
        history = History()
        gameHasEnded = false
        requestZeroBrainStorm()
        delegate?.boardDidUpdate(pieces: pieces)
    }
    
    func spawnPseudoPieces() {
        clear()
        for row in 0..<dimension {
            for col in 0..<dimension {
                pieces[row][col] = Piece.random()
            }
        }
        delegate?.boardDidUpdate(pieces: pieces)
    }
    
    /**
     Redo last move
     */
    func redo() {
        if let co = history.restore() {
            set(co, curPlayer)
            curPlayer = curPlayer.next()
            delegate?.boardDidUpdate(pieces: pieces)
        }
    }
    
    /**
     Undo last move
     */
    func undo() {
        if let co = history.revert() {
            set(co, .none)
            gameHasEnded = false
            curPlayer = curPlayer.next()
            delegate?.boardDidUpdate(pieces: pieces)
        }
    }
    
    /**
     Override the piece at the given coordinate with the supplied piece by force
     */
    func set(_ co: Coordinate, _ piece: Piece) {
        pieces[co.row][co.col] = piece
    }
    
    func put(at co: Coordinate) {
        if !isValid(co) || pieces[co.row][co.col] != .none || gameHasEnded {
            return
        }
        set(co, curPlayer)
        history.push(co)
        delegate?.boardDidUpdate(pieces: pieces)
        
        if let winner = hasWinner() {
            gameHasEnded = true
            let cos = findWinningCoordinates()
            delegate?.gameHasEnded(winner: winner, coordinates: cos)
        }
        
        curPlayer = curPlayer.next()
        requestZeroBrainStorm()
    }
    
    func hasWinner() -> Piece? {
        if history.stack.count == 0 { return nil}
        let blackScore = heuristicEvaluator.evaluate(for: .black)
        let whiteScore = heuristicEvaluator.evaluate(for: .white)
        if blackScore > Threat.win || whiteScore >  Threat.win {
            return blackScore > whiteScore ? .black : .white
        }
        return nil
    }
    
    /**
     Find the coordinates of winning pieces
     */
    public func findWinningCoordinates() -> [Coordinate] {
        var winningCos = [Coordinate]()
        let row = history.stack.last!.row, col = history.stack.last!.col
        let color = pieces[row][col]
        (-4...0).forEach {
            var i = $0, buff = [Coordinate]()
            
            // Vertical
            for q in i...(i+4) {
                let co = Coordinate(col: col + q, row: row)
                if !isValid(co) || pieces[co.row][co.col] == .none || pieces[co.row][co.col] != color {
                    buff.removeAll()
                    break
                }
                buff.append(co)
            }
            winningCos.append(contentsOf: buff)
            buff.removeAll()
            
            // Horizontal
            for q in i...(i+4) {
                let co = Coordinate(col: col, row: row + q)
                if !isValid(co) || pieces[co.row][co.col] == .none || pieces[co.row][co.col] != color {
                    buff.removeAll()
                    break
                }
                buff.append(co)
            }
            winningCos.append(contentsOf: buff)
            buff.removeAll()
            
            // Diagnol slope = 1
            for q in i...(i+4) {
                let co = Coordinate(col: col + q, row: row + q)
                if !isValid(co) || pieces[co.row][co.col] == .none || pieces[co.row][co.col] != color {
                    buff.removeAll()
                    break
                }
                buff.append(co)
            }
            winningCos.append(contentsOf: buff)
            buff.removeAll()
            
            //diagnol slope = -1
            for q in i...(i+4) {
                let co = Coordinate(col: col + q, row: row - q)
                if !isValid(co) || pieces[co.row][co.col] == .none || pieces[co.row][co.col] != color {
                    buff.removeAll()
                    break
                }
                buff.append(co)
            }
            winningCos.append(contentsOf: buff)
            buff.removeAll()
        }
        return winningCos
    }
    
    /**
     This would only take effect if it is ZeroPlus's turn.
     */
    func requestZeroBrainStorm() {
        if (zeroAi == curPlayer || zeroXzero) && !gameHasEnded {
            triggerZeroBrainstorm()
        }
    }
    
    /**
     Use this to allow ZeroPlus to make a move
     */
    func triggerZeroBrainstorm() {
        if gameHasEnded {return}
        zeroActivityQueue.async {[unowned self] in
            self.zeroPlus.getMove(for: self.curPlayer)
        }
    }

    /**
     ZeroPlus has returned the extrapolated best move
     */
    func bestMoveExtrapolated(co: Coordinate) {
        put(at: co)
    }
    
    func isValid(_ co: Coordinate) -> Bool {
        return co.col >= 0 && co.row >= 0 && co.row < dimension && co.col < dimension
    }

    func serialize() -> String {
        return "\(dimension)|" + history.serialize()
    }
    
    func load(_ game: String) {
        let segments = game.split(separator: "|")
        dimension = Int(segments[0])!
        restart() // Reset everything
        history.load(String(segments[1]))
        for co in history.stack { // Replay history
            set(co, curPlayer)
            curPlayer = curPlayer.next()
        }
        delegate?.boardDidUpdate(pieces: pieces)
    }
}

protocol BoardDelegate {
    func boardDidUpdate(pieces: [[Piece]])
    func gameHasEnded(winner: Piece, coordinates: [Coordinate])
}

extension Board: CustomStringConvertible {
    public var description: String {
        get {
            var str = ""
            pieces.forEach { row in
                row.forEach { col in
                    switch col {
                    case .none: str += "- "
                    case .black: str += "* "
                    case .white: str += "o "
                    }
                }
                str += "\n"
            }
            return str
        }
    }
}
