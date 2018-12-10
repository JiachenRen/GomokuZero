//
//  Board.swift
//  Gomoku Zero
//
//  Created by Jiachen Ren on 10/5/18.
//  Copyright © 2018 Jiachen Ren. All rights reserved.
//

import Foundation

class Board: ZeroPlusDelegate {
    var dimension: Int {
        didSet {
            if dimension != oldValue {
                restart()
            }
        }
    }
    
    var cortex: CortexProtocol {
        return zeroPlus.cortex
    }
    
    // The arrangement of pieces on the board. A 2D array.
    var pieces = [[Piece]]()
    weak var delegate: BoardDelegate?
    var history = History()
    
    var curPlayer: Piece = .black
    var zeroIdentity: Piece = .none
    var zeroPlus = ZeroPlus() {
        didSet {
            zeroPlus.delegate = self
        }
    }
    
    // Secondary AI for skirmish, don't forget to set the delegate!
    var zeroPlus2: ZeroPlus? {
        didSet {
            zeroPlus2?.delegate = self
        }
    }
    
    var zeroXzero = false {
        didSet {
            cancel()
        }
    }
    var zeroIsThinking = false
    var calcStartTime: TimeInterval = 0
    var gameStartTime: TimeInterval = 0
    var gameCompletionHandler: ((Piece) -> Void)?
    var restartDelay: TimeInterval = 1
    var looped: Bool = false
    var battles: Int = 0
    var saveDir: String = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
    var gameHasEnded = false {
        didSet {
            Zobrist.heuristicHash = [Zobrist: Int]() // Clear heuristic map
            Zobrist.orderedMovesHash = [Zobrist: [Move]]() // Clear ordered moves map.
        }
        willSet {
            if !newValue {
                gameStartTime = Date().timeIntervalSince1970
            }
        }
    }
    let zeroActivityQueue = DispatchQueue(label: "zeroPlus", attributes: .concurrent)
    var zeroWorkItem: DispatchWorkItem?
    var zero2WorkItem: DispatchWorkItem?
    
    init(dimension: Int) {
        self.dimension = dimension
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
        if !isValid(co, dimension) || pieces[co.row][co.col] != .none {
            return
        }
        set(co, curPlayer)
        history.push(co)
        delegate?.boardDidUpdate(pieces: pieces)
        
        if let winner = hasWinner() {
            gameHasEnded = true
            let cos = findWinningCoordinates()
            if looped {
                log(winner)
                gameCompletionHandler?(winner)
                DispatchQueue.global().async {[unowned self] in
                    Thread.sleep(forTimeInterval: self.restartDelay)
                    self.restart()
                }
            }
            
            delegate?.gameHasEnded(winner: winner, coordinates: cos, popDialogue: !looped)
        }
        
        curPlayer = curPlayer.next()
        requestZeroBrainStorm()
    }
    
    func log(_ winner: Piece) {
        var fileName = "battle_\(battles)_"
        let steps = history.stack.count
        switch winner {
        case .none: fileName += "draw"
        case .black: fileName += "b_wins_@step=\(steps)"
        case .white: fileName += "w_wins_@step=\(steps)"
        }
        let timeElapsed = Date().timeIntervalSince1970 - gameStartTime
        fileName += "_t=\(timeElapsed)s"
        fileName += ".gzero"
        let url = URL(fileURLWithPath: saveDir).appendingPathComponent(fileName)
        do {
            print("battle # \(battles), \(winner) wins @ step = \(steps)")
            print("time elapsed: \(timeElapsed)")
            print("board: \n\(Zobrist(matrix: pieces))")
            print("saving to \(url)")
            try serialize().write(to: url, atomically: true, encoding: .utf8)
        } catch let err {
            print(err)
        }
        battles += 1
    }
    
    func hasWinner() -> Piece? {
        if history.stack.count == 0 {
            return nil
        } else if history.stack.count == dimension * dimension {
            // Such a sneaky bug!!! .none is for optional!!!
            return Piece.none
        }
        zeroPlus.zobrist = Zobrist(matrix: pieces)
        let score = cortex.threatCoupledHeuristic()
        
        if abs(score) >= Evaluator.win {
            return score > 0 ? .black : .white
        }
        
        // Game is still in progress
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
                if !isValid(co, dimension) || pieces[co.row][co.col] == .none || pieces[co.row][co.col] != color {
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
                if !isValid(co, dimension) || pieces[co.row][co.col] == .none || pieces[co.row][co.col] != color {
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
                if !isValid(co, dimension) || pieces[co.row][co.col] == .none || pieces[co.row][co.col] != color {
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
                if !isValid(co, dimension) || pieces[co.row][co.col] == .none || pieces[co.row][co.col] != color {
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
        if zeroXzero {
            if let zeroPlus2 = self.zeroPlus2 { // If a second AI configuration is present
                if curPlayer == zeroPlus2.identity {
                    triggerZero2BrainStorm()
                } else {
                    triggerZeroBrainstorm()
                }
            }
        } else if zeroIdentity == curPlayer && !gameHasEnded {
            triggerZeroBrainstorm()
        }
    }
    
    func triggerZero2BrainStorm() {
        calcStartTime = Date().timeIntervalSince1970
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
        calcStartTime = Date().timeIntervalSince1970
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

}

/// Serialization
extension Board {
    func serialize() -> String {
        return "\(dimension)|" + history.serialize()
    }
    
    func load(_ game: String) {
        let segments = game.split(separator: "|")
        dimension = Int(segments[0])!
        clear() // Reset everything
        history.load(String(segments[1]))
        for co in history.stack { // Replay history
            set(co, curPlayer)
            curPlayer = curPlayer.next()
        }
        delegate?.boardDidUpdate(pieces: pieces)
    }
}

extension Board: CustomStringConvertible {
    var description: String {
        let raw = Zobrist(matrix: pieces).description
        let colMarks = (1...dimension).reduce("") {"\($0)\t\($1)"}
        let processed = raw.replacingOccurrences(of: " ", with: "\t")
            .split(separator: "\n")
            .enumerated()
            .map {"\($0 + 1)\t\($1)"}
            .reduce(colMarks) {"\($0)\n\n\($1)"}
        return processed
    }
}

protocol BoardDelegate: AnyObject {
    func boardDidUpdate(pieces: [[Piece]])
    func gameHasEnded(winner: Piece, coordinates: [Coordinate], popDialogue: Bool)
}

func isValid(_ co: Coordinate, _ dim: Int) -> Bool {
    return co.col >= 0 && co.row >= 0 && co.row < dim && co.col < dim
}
