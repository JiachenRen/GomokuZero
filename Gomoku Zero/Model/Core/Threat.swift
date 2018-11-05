//
//  ThreatType.swift
//  Gomoku Zero
//
//  Created by Jiachen Ren on 10/7/18.
//  Copyright © 2018 Jiachen Ren. All rights reserved.
//

import Foundation

/// Score assignment for different types of threat
enum Threat: Int {
    static let win = 1_000_000_000_000_000
    static let interesting = Threat.straightPokedThree.rawValue - 1
    
    // A large number that nullifies the influence of the rest
    case five = 10_000_000_000_000_000
    
    case straightFour =  1_000_000
    case straightPokedFour = 100_010
    case blockedFour =   100_000
    case blockedPokedFour = 99_990
    
    case straightThree = 10_000
    case straightPokedThree = 9_990
    case blockedThree =  1_020
    case blockedPokedThree = 1_010
    
    case straightTwo = 1_000
    case straightPokedTwo = 990
    case blockedTwo = 100
    case blockedPokedTwo = 90
    
    case none = 0
}

extension Threat: Comparable {
    static func < (lhs: Threat, rhs: Threat) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
}

extension Threat: CustomStringConvertible {
    var description: String {
        switch self {
        case .five: return "5"
        case .straightFour: return "s-4"
        case .straightThree: return "s-3"
        case .straightTwo: return "s-2"
        case .blockedFour: return "b-4"
        case .blockedThree: return "b-3"
        case .blockedTwo: return "b-2"
        case .straightPokedFour: return "s-p-4"
        case .straightPokedThree: return "s-p-3"
        case .straightPokedTwo: return "s-p-2"
        case .blockedPokedFour: return "b-p-4"
        case .blockedPokedThree: return "b-p-3"
        case .blockedPokedTwo: return "b-p-2"
        case .none: return "none"
        }
    }
}

/// Core threat evaluation algorithms
extension Threat {
    static var seqHashMap: Dictionary<[Piece], Int> = Dictionary()
    static let seqHashQueue = DispatchQueue(label: "seqHashQueue")
    
    static func map(for player: Piece, at co: Coordinate, pieces: [[Piece]]) -> [[Piece]] {
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
    static func analyze(for player: Piece, at co: Coordinate, pieces: [[Piece]]) -> [Threat] {
        return map(for: player, at: co, pieces: pieces)
            .map{analyzeThreats(seq: $0, for: player)}
            .flatMap{$0}
    }
    
    /**
     Point evaluation
     */
    static func evaluate(for player: Piece, at co: Coordinate, pieces: [[Piece]]) -> Int {
        let linearScores = map(for: player, at: co, pieces: pieces).map{ seq -> Int in
            return cacheOrGet(seq: seq, for: player) // Convert sequences to threat types
        }
        return linearScores.reduce(0) {$0 + $1}
    }
    
    
    static func convertToScore(threats: [Threat]) -> Int {
        return threats.map{$0.rawValue}  // Convert threat types to score
            .reduce(0){$0 + $1} // Sum it up
    }
    
    /**
     Results in 1/3 speed up
     */
    static func cacheOrGet(seq: [Piece], for player: Piece) -> Int {
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
    private static func analyzeThreats(seq: [Piece], for player: Piece) -> [Threat] {
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

enum Head {
    case blocked
    case straight
}

enum Sequence {
    case five, four, three, two
    case pokedFour, pokedThree, pokedTwo
    case none
    
    static func resolve(same: Int, gap: Int, gapIdx: Int) -> Sequence {
        if gap > 1 {return .none}
        if gap == 1 {
            switch same {
            case 2: return .pokedTwo
            case 3: return .pokedThree
            case 4: return .pokedFour
            default:
                if same > 5 {
                    if gapIdx == 5 || same - gapIdx == 5 {
                        return .five
                    }
                }
                return .none
            }
        } else { // gap == 0
            switch same {
            case 2: return .two
            case 3: return .three
            case 4: return .four
            case 5: return .five
            default: return .none
            }
        }
    }
    
    func toThreatType(head: Head) -> Threat {
        switch head {
        case .blocked:
            switch self {
            case .five: return .five
            case .four: return .blockedFour
            case .three: return .blockedThree
            case .two: return .blockedTwo
            case .pokedFour: return .blockedPokedFour
            case .pokedThree: return .blockedPokedThree
            case .pokedTwo: return .blockedPokedTwo
            case .none: return .none
            }
        case .straight:
            switch self {
            case .five: return .five
            case .four: return .straightFour
            case .three: return .straightThree
            case .two: return .straightTwo
            case .pokedFour: return .straightPokedFour
            case .pokedThree: return .straightPokedThree
            case .pokedTwo: return .straightPokedTwo
            case .none: return .none
            }
        }
    }
}
