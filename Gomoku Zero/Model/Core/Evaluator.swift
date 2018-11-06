//
//  Evaluator.swift
//  Gomoku Zero
//
//  Created by Jiachen Ren on 11/6/18.
//  Copyright © 2018 Jiachen Ren. All rights reserved.
//

import Foundation

/**
 Linearizes and analyzes the 2D matrix provided by the data source, categorizes and hashes linear sequences into
 threat types. Assign score for a specific point or game state based on threat potential
 */
class Evaluator {
    var seqHashMap: Dictionary<[Piece], Int> = Dictionary()
    let seqHashQueue = DispatchQueue(label: "seqHashQueue")
    var dataSource: EvaluatorDataSource!
    var pieces: [[Piece]] {
        return dataSource.pieces
    }
    
    static let win = 10_000_000_000_000_00
    var weights: Dictionary<Threat, Int> = [
        .five: 10_000_000_000_000_000, // 5
        .straightFour: 1_000_000,      // s4
        .straightPokedFour: 100_010,   // sp4
        .blockedFour: 100_000,         // b4
        .blockedPokedFour: 99_990,     // bp4
        .straightThree: 50_200,        // s3
        .straightPokedThree: 50190,    // sp3
        .blockedThree: 16740,          // b3
        .blockedPokedThree: 16720,     // bp3
        .straightTwo: 15000,           // s2
        .straightPokedTwo: 14990,      // sp2
        .blockedTwo: 5000,             // b2
        .blockedPokedTwo: 4990,        // bp2
        .none: 0
    ]
    
    
    init(_ dataSource: EvaluatorDataSource?) {
        self.dataSource = dataSource
    }
    
    /**
     Extract the weight for a specific threat type.
     - Returns: weight assignment for the threat
     */
    func val(_ threat: Threat) -> Int {
        return weights[threat]!
    }
    
    func sequentialize(for player: Piece, at co: Coordinate) -> [[Piece]] {
        let row = co.row, col = co.col, dim = pieces.count
        let opponent = player.next()
        
        func isValid(col: Int, row: Int) -> Bool {
            return col >= 0 && row >= 0 && row < dim && col < dim
        }
        
        // Linearize the board for higher efficiency
        func explore(x: Int, y: Int) -> [Piece] {
            var seq = [Piece]()
            var empty = 0
            loop: for i in 1...5  {
                let curRow = row + y * i, curCol = col + x * i
                if !isValid(col: curCol, row: curRow) {
                    seq.append(opponent) // It doesn't matter which color the player is, hitting the wall == an opposite piece
                    break
                }
                let piece = pieces[curRow][curCol]
                switch piece {
                case .none:
                    seq.append(.none)
                    if empty > 0 {
                        break loop
                    }
                    empty += 1
                default:
                    seq.append(piece)
                    if piece == opponent {
                        break loop
                    }
                }
            }
            return seq
        }
        
        
        
        func genSequence(x1: Int, y1: Int, x2: Int, y2: Int) -> [Piece] {
            var seqA: [Piece] = explore(x: x1, y: y1).reversed()
            seqA.append(player)
            seqA.append(contentsOf: explore(x: x2, y: y2))
            return seqA
        }
        
        let hSeq = genSequence(x1: -1, y1: 0, x2: 1, y2: 0)    // Horizontal (from left to right)
        let vSeq = genSequence(x1: 0, y1: -1, x2: 0, y2: 1)    // Vertical (from up to down)
        let d1Seq = genSequence(x1: -1, y1: 1, x2: 1, y2: -1)  // Diagnally (from lower left to upper right)
        let d2Seq = genSequence(x1: -1, y1: -1, x2: 1, y2: 1) // Diagnally (from upper left to lower right)
        
        return [hSeq, vSeq, d1Seq, d2Seq]
    }
    
    /**
     - Returns: An array containing identified threats, e.g. [.straightPokedThree, .blockedFour]
     */
    func analyze(for player: Piece, at co: Coordinate) -> [Threat] {
        return sequentialize(for: player, at: co)
            .map{analyzeThreats(seq: $0, for: player)}
            .flatMap{$0}
    }
    
    /**
     Point evaluation
     */
    func evaluate(for player: Piece, at co: Coordinate) -> Int {
        let linearScores = sequentialize(for: player, at: co).map{ seq -> Int in
            return cacheOrGet(seq: seq, for: player) // Convert sequences to threat types
        }
        return linearScores.reduce(0) {$0 + $1}
    }
    
    
    func convertToScore(threats: [Threat]) -> Int {
        return threats.map{val($0)}  // Convert threat types to score
            .reduce(0){$0 + $1} // Sum it up
    }
    
    /**
     Results in 1/3 speed up
     */
    private func cacheOrGet(seq: [Piece], for player: Piece) -> Int {
        if let cached = seqHashMap[seq] {
            return cached
        } else {
            let threats = analyzeThreats(seq: seq, for: player)
            let score = convertToScore(threats: threats)
            seqHashQueue.sync {
                seqHashMap[seq] = score
            }
            return score
        }
    }
    
    // The results could be hashed!!!
    private func analyzeThreats(seq: [Piece], for player: Piece) -> [Threat] {
        let opponent = player.next()
        let leftBlocked = seq.first! == opponent
        let rightBlocked = seq.last! == opponent
        
        typealias Pattern = (same: Int, gap: Int, startIdx: Int, endIdx: Int, gapIdx: Int)
        func findPatterns(from a: Int, to b: Int) -> [Pattern] {
            var gap = 0
            var same = 0
            var started = false
            var startIdx = -1
            var endIdx = -1
            var pendingGap = 0
            var gapIdx = -1
            var identifiedPatterns = [Pattern]()
            for i in a...b {
                let piece = seq[i]
                assert(piece != opponent)
                if piece == .none {
                    if started {
                        pendingGap += 1
                    }
                } else {
                    same += 1
                    gap += pendingGap
                    if gap > 1 {
                        endIdx = i - 2
                        
                        let pattern = (same - 1, 1, startIdx, endIdx, gapIdx)
                        identifiedPatterns.append(pattern)
                        
                        // Reset counters
                        startIdx = endIdx
                        var tmp = 0
                        while seq[startIdx - 1] == player {
                            startIdx -= 1
                            tmp += 1
                        }
                        endIdx = startIdx
                        same = tmp + 1
                        gap = 1
                    }
                    if pendingGap == 1 {
                        gapIdx = i - 1 - startIdx
                    }
                    pendingGap = 0
                    
                    if started == false {
                        startIdx = i
                    }
                    started = true
                }
                if pendingGap > 1 {
                    endIdx = i - pendingGap
                    let pattern = (same, gap, startIdx, endIdx, gapIdx)
                    identifiedPatterns.append(pattern)
                    
                    // Reset counters
                    pendingGap = 0
                    startIdx = i
                    same = 0
                    gap = 0
                    endIdx = i
                    started = false
                }
            }
            
            endIdx = b
            if pendingGap == 1 {
                endIdx -= 1
            }
            let pattern = (same, gap, startIdx, endIdx, gapIdx)
            identifiedPatterns.append(pattern)
            
            return identifiedPatterns.filter{$0.same > 1}
        }
        
        // Some inefficiency here... if one or both ends terminate with an opponent piece
        if leftBlocked && rightBlocked {
            if seq.count - 2 < 5 {
                return [.none]
            } else {
                let startIdx = 1, endIdx = seq.count - 2
                let patterns = findPatterns(from: startIdx, to: endIdx)
                let resolved = patterns.map{Sequence.resolve(same: $0.same, gap: $0.gap, gapIdx: $0.gapIdx)}
                return zip(patterns, resolved).map {(pattern, sequence) -> Threat in
                    let blocked = pattern.startIdx == startIdx || pattern.endIdx == endIdx
                    let type: Head = (blocked ? .blocked : .straight)
                    return sequence.toThreatType(head: type)
                }
            }
        } else if leftBlocked  {
            let patterns = findPatterns(from: 1, to: seq.count - 1)
            let resolved = patterns.map{Sequence.resolve(same: $0.same, gap: $0.gap, gapIdx: $0.gapIdx)}
            return zip(patterns, resolved).map {(pattern, sequence) in
                let type: Head = (pattern.startIdx == 1 ? .blocked : .straight)
                return sequence.toThreatType(head: type)
            }
        } else if rightBlocked {
            let patterns = findPatterns(from: 0, to: seq.count - 2)
            let resolved = patterns.map{Sequence.resolve(same: $0.same, gap: $0.gap, gapIdx: $0.gapIdx)}
            return zip(patterns, resolved).map {(pattern, sequence) in
                let type: Head = (pattern.endIdx == seq.count - 2 ? .blocked : .straight)
                return sequence.toThreatType(head: type)
            }
        }
        
        // Free ends
        return findPatterns(from: 0, to: seq.count - 1)
            .map{Sequence.resolve(same: $0.same, gap: $0.gap, gapIdx: $0.gapIdx)}
            .map{$0.toThreatType(head: .straight)}
    }
}
