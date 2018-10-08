//
//  Evaluator.swift
//  Gomoku Zero
//
//  Created by Jiachen Ren on 10/6/18.
//  Copyright © 2018 Jiachen Ren. All rights reserved.
//

import Foundation

class Evaluator {
    
    static var hashMap: Dictionary<[Piece], Int> = Dictionary()
    
    /**
     Point evaluation
     */
    static func evaluate(for player: Piece, at co: Coordinate, pieces: [[Piece]]) -> Int {
        let row = co.row, col = co.col, dim = pieces.count
        let opponent = player.next()
        
        func isValid(col: Int, row: Int) -> Bool {
            return col >= 0 && row >= 0 && row < dim && col < dim
        }
        
        // Linearize the board for higher efficiency
        func explore(x: Int, y: Int) -> [Piece] {
            var seq = [Piece]()
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
                default:
                    seq.append(piece)
                    if piece == opponent {
                        break loop
                    }
                }
            }
            return seq
        }
        
        
        typealias SequencePair = (new: [Piece], org: [Piece])
        func genSequence(x1: Int, y1: Int, x2: Int, y2: Int) -> SequencePair {
            var seqA: [Piece] = explore(x: x1, y: y1).reversed()
            var org = seqA // The sequence without the addition of the new piece, since we are only concerned about difference
            seqA.append(player)
            org.append(.none)
            let seqB = explore(x: x2, y: y2)
            seqA.append(contentsOf: seqB)
            org.append(contentsOf: seqB)
            return (seqA, org)
        }
        
        let hSeqPair = genSequence(x1: -1, y1: 0, x2: 1, y2: 0)    // Horizontal (from left to right)
        let vSeqPair = genSequence(x1: 0, y1: -1, x2: 0, y2: 1)    // Vertical (from up to down)
        let d1SeqPair = genSequence(x1: -1, y1: 1, x2: 1, y2: -1)  // Diagnally (from lower left to upper right)
        let d2SeqPair = genSequence(x1: -1, y1: -1, x2: 1, y2: 1) // Diagnally (from upper left to lower right)
        
        

        
        let seqPairs = [hSeqPair, vSeqPair, d1SeqPair, d2SeqPair]
        
//        print("coordinate: \(co)")
//        print(seqPairs)
        
        
        
        let linearScores = seqPairs.map{ seqPair -> Int in
            let newScore = sequenceToScore(seq: seqPair.new, for: player) // Convert sequences to threat types
            let oldScore = sequenceToScore(seq: seqPair.org, for: player) // Convert sequences to threat types
//            print("old: \(orgThreats)")
//            print("new: \(newThreats)")
            return newScore - oldScore
        }
        
        return linearScores.reduce(0) {$0 + $1}
    }
    
    static func convertToScore(threats: [ThreatType]) -> Int {
        return threats.map{$0.rawValue}  // Convert threat types to score
            .reduce(0){$0 + $1} // Sum it up
    }
    
    static func sequenceToScore(seq: [Piece], for player: Piece) -> Int {
        if let cached = hashMap[seq] {
            return cached
        } else {
            let threats = analyzeThreats(seq: seq, for: player)
            let score = convertToScore(threats: threats)
            hashMap[seq] = score
            return score
        }
    }
    
    // The results could be hashed!!!
    static func analyzeThreats(seq: [Piece], for player: Piece) -> [ThreatType] {
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
                return zip(patterns, resolved).map {(pattern, sequence) -> ThreatType in
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
