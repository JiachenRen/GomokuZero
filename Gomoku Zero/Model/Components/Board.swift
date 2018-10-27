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
    var zeroIdentity: Piece = .none
    var zeroPlus = ZeroPlus()
    var zeroPlus2: ZeroPlus? // Secondary AI for skirmish, don't forget to set the delegate!
    var zeroXzero = false {
        didSet {
            cancel()
        }
    }
    var zeroIsThinking = false
    var gameHasEnded = false {
        didSet {
            Zobrist.blackOrderedMovesMap = Dictionary<Zobrist, [Move]>() // Clear ordered moves map.
            Zobrist.whiteOrderedMovesMap = Dictionary<Zobrist, [Move]>()
        }
    }
    let zeroActivityQueue = DispatchQueue(label: "zeroPlus", attributes: .concurrent)
    var zeroWorkItem: DispatchWorkItem?
    var zero2WorkItem: DispatchWorkItem?
    
    init(dimension: Int) {
        heuristicEvaluator = HeuristicEvaluator()
        self.dimension = dimension
        heuristicEvaluator.delegate = self
        zeroPlus.delegate = self
        restart()
    }
    
    func clear() {
        cancel()
        pieces = [[Piece]](repeating: Array(repeatElement(Piece.none, count: dimension)), count: dimension)
        curPlayer = .black
        history = History()
        gameHasEnded = false
    }
    
    func cancel() {
        zeroWorkItem?.cancel()
        zero2WorkItem?.cancel()
        zeroWorkItem?.wait()
        zero2WorkItem?.wait()
    }
    
    func restart() {
        clear()
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
        if zeroIsThinking {return}
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
        if zeroIsThinking {return}
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
        if zeroIsThinking || gameHasEnded {
            return
        }
        if !isValid(co) || pieces[co.row][co.col] != .none  {
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
        if zeroIdentity == curPlayer && !gameHasEnded {
            triggerZeroBrainstorm()
        } else if zeroXzero {
            if let zeroPlus2 = self.zeroPlus2 { // If a second AI configuration is present
                if curPlayer == zeroPlus2.identity {
                    triggerZero2BrainStorm()
                } else {
                    triggerZeroBrainstorm()
                }
            }
        }
    }
    
    func triggerZero2BrainStorm() {
        if gameHasEnded {return}
        zeroIsThinking = true
        zero2WorkItem = DispatchWorkItem {
            self.zeroPlus2?.getMove(for: self.curPlayer)
        }
        zeroActivityQueue.async(execute: zero2WorkItem!)
    }
    
    /**
     Use this to allow ZeroPlus to make a move
     */
    func triggerZeroBrainstorm() {
        if gameHasEnded {return}
        zeroIsThinking = true
        zeroWorkItem = DispatchWorkItem {
            self.zeroPlus.getMove(for: self.curPlayer)
        }
        zeroActivityQueue.async(execute: zeroWorkItem!)
    }

    /**
     ZeroPlus has returned the extrapolated best move
     */
    func bestMoveExtrapolated(co: Coordinate) {
        zeroIsThinking = false
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
