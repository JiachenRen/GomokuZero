//
//  ZobristBoard.swift
//  Gomoku Zero
//
//  Created by Jiachen Ren on 10/8/18.
//  Copyright © 2018 Jiachen Ren. All rights reserved.
//

import Foundation

typealias ZobristTable = [[[Int]]]
typealias HeuristicMap = Dictionary<Zobrist, Int>

var hashCollisions: Int = 0
class Zobrist: Hashable {
    
    // This is for accomodating different board dimensions
    private static var tables = Dictionary<Int,ZobristTable>()
    
    // Note that the hash maps only supports dimension of up to 19.
    
    /// Hashed heuristic values of nodes
    static var hueristicHash = [HeuristicMap](repeatElement(HeuristicMap(), count: 50))
    
    ///
    static var segregatedHMap = Dictionary<Zobrist, [[Int?]]>()
    
    /// Hashed ordered moves
    static var orderedMovesHash = Dictionary<Zobrist, [Move]>()
    
    /// Slightly boosts performance at a neglegible risk of judging two diffenrent game states to be the same.
    static var strictEqualityCheck = false
    
    let dim: Int
    var matrix = [[Piece]]()
    var hashValue = 0
    
    init(zobrist: Zobrist) {
        self.dim = zobrist.dim
        self.matrix = zobrist.matrix
        hashValue = zobrist.hashValue
    }
    
    init(matrix: [[Piece]]) {
        self.dim = matrix.count
        self.matrix = matrix
        
        if Zobrist.tables[dim] == nil {
            // Make a new table if a table of the new dimension does not exist
            let table = Zobrist.makeZobristTable(dim: dim)
            Zobrist.tables[dim] = table
        }
        hashValue = computeInitialHash()
    }
    
    /**
     Compute the initial hashValue by cross-referencing the pieces in the matrix and the shared table.
     - Note: when changes are made to the matrix, the hashValue is updated accordingly by a much more
             light-weight algorithm.
     */
    private func computeInitialHash() -> Int {
        var hash = 0
        for i in 0..<dim {
            for q in 0..<dim {
                let piece = matrix[i][q]
                switch piece {
                case .none: continue
                case .black: hash ^= Zobrist.tables[dim]![i][q][0]
                case .white: hash ^= Zobrist.tables[dim]![i][q][1]
                }
            }
        }
        return hash
    }
    
    /**
     Due to the nature of xor operation, putting and reverting a piece use the same operation
     */
    private func updateHashValue(at co: Coordinate, _ piece: Piece) {
        hashValue ^= Zobrist.tables[dim]![co.row][co.col][piece == .black ? 0 : 1]
    }
    
    func put(at co: Coordinate, _ piece: Piece) {
        matrix[co.row][co.col] = piece
        updateHashValue(at: co, piece)
    }
    
    func revert(at co: Coordinate) {
        let original = matrix[co.row][co.col]
        matrix[co.row][co.col] = .none
        updateHashValue(at: co, original)
    }
    
    static func == (lhs: Zobrist, rhs: Zobrist) -> Bool {
        hashCollisions += 1
        if strictEqualityCheck {
            let dim = lhs.dim
            for i in 0..<dim {
                for q in 0..<dim {
                    if lhs.matrix[i][q] != rhs.matrix[i][q] {
                        return false
                    }
                }
            }
            return true
        }
        // Loads faster, but could be faulty!
        return lhs.hashValue == rhs.hashValue
    }
    
    func get(_ co: Coordinate) -> Piece {
        return matrix[co.row][co.col]
    }
    
    /**
     Generate a table filled with random
     */
    static func makeZobristTable(dim: Int) -> ZobristTable {
        var table = [[[Int]]]()
        for _ in 0..<dim {
            var col = [[Int]]()
            for _ in 0..<dim {
                var piece = [Int]()
                for _ in 0...1 {
                    let rand = Int.random(in: 0..<Int.max)
                    piece.append(rand)
                }
                col.append(piece)
            }
            table.append(col)
        }
        return table
    }
    
}

extension Zobrist: CustomStringConvertible {
    public var description: String {
        get {
            var str = ""
            matrix.forEach { row in
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
