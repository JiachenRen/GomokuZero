//
//  Board.swift
//  Gomoku Zero
//
//  Created by Jiachen Ren on 10/5/18.
//  Copyright © 2018 Jiachen Ren. All rights reserved.
//

import Foundation

class Board {
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
    
    var curPlayer: Piece = .black
    
    init(dimension: Int) {
        self.dimension = dimension
        restart()
    }
    
    func clear() {
        pieces = [[Piece]](repeating: Array(repeatElement(Piece.none, count: dimension)), count: dimension)
    }
    
    func restart() {
        clear()
        curPlayer = .black
        history = History()
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
        if !isValid(co) || pieces[co.row][co.col] != .none { return }
        set(co, curPlayer)
        history.push(co)
        curPlayer = curPlayer.next()
        delegate?.boardDidUpdate(pieces: pieces)
    }
    
    func isValid(_ co: Coordinate) -> Bool {
        return co.col >= 0 && co.row >= 0 && co.row < dimension && co.col < 19
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
}
