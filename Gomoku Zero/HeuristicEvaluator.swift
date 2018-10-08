//
//  HeuristicEvaluator.swift
//  Gomoku Zero
//
//  Created by Jiachen Ren on 10/7/18.
//  Copyright © 2018 Jiachen Ren. All rights reserved.
//

import Foundation

class HeuristicEvaluator {
    var counter = Counter()
    var dim: Int = 0
    var delegate: HeuristicEvaluatorDelegate!
    var pieces: [[Piece]] {
        return delegate.pieces
    }
    var color: Piece = .black
    
    
    private func horizontalInspection() {
        var row = 0
        while row < dim {
            var col = 0
            while col < dim {
                let currentPiece = pieces[row][col]
                if currentPiece == self.color {
                    let leftCo = Coordinate(col: col - 1, row)
                    var leftBlocked: Bool
                    if isValid( leftCo) {
                        leftBlocked = pieces[leftCo.row][leftCo.col] != .none
                    } else {
                        leftBlocked = true
                    }
                    
                    var gaps = 0, gapsBuff = 0, same = 1, rightBlocked = false, i = 1
                    //                    let curMillis = NSDate() //debug
                    while(i <= 5) {
                        let nextCo = Coordinate(col: col + i, row: row)
                        if isValid( nextCo) {
                            let next = pieces[nextCo.row][nextCo.col]
                            if next != .none {
                                if next == currentPiece {
                                    gaps += gapsBuff
                                    same += 1
                                    gapsBuff = 0
                                } else {
                                    rightBlocked = true
                                    break
                                }
                            } else {
                                gapsBuff += 1
                            }
                        } else {
                            rightBlocked = true
                            break
                        }
                        i += 1
                    }
                    //                    print(NSDate().timeIntervalSince(curMillis as Date))
                    if gaps <= 1 {
                        if same != 5 {col += i - 1}
                        counter.interpret(leftBlocked, rightBlocked, i, same, gaps)
                    }
                }
                col += 1
            }
            row += 1
        }
    }
    
    private func verticalInspection() {
        var col = 0
        while col < dim {
            var row = 0
            while row < dim {
                let currentPiece = pieces[row][col]
                if currentPiece == self.color {
                    let upperCo = Coordinate(col: col, row - 1)
                    var topBlocked: Bool
                    if isValid( upperCo) {
                        topBlocked = pieces[upperCo.row][upperCo.col] != .none
                    } else {
                        topBlocked = true
                    }
                    
                    var gaps = 0, gapsBuff = 0, same = 1, bottomBlocked = false, i = 1
                    while(i <= 5) {
                        let nextCo = Coordinate(col: col, row: row + i)
                        if isValid( nextCo) {
                            let next = pieces[nextCo.row][nextCo.col]
                            if next != .none {
                                if next == currentPiece {
                                    gaps += gapsBuff
                                    same += 1
                                    gapsBuff = 0
                                } else {
                                    bottomBlocked = true
                                    break
                                }
                            } else {
                                gapsBuff += 1
                            }
                        } else {
                            bottomBlocked = true
                            break
                        }
                        i += 1
                    }
                    if (gaps <= 1) {
                        if same != 5 {row += i - 1}
                        counter.interpret(topBlocked, bottomBlocked, i, same, gaps)
                    }
                }
                row += 1
            }
            col += 1
        }
    }
    
    private func diagnalInspectionUllr() {
        var row = 0
        while row <= dim - 5 {
            var col = 0
            while col <= dim - 5 {
                let currentPiece = pieces[row][col]
                if currentPiece == self.color {
                    let prevCo = Coordinate(col: col - 1, row: row - 1)
                    var headBlocked: Bool = false, repetitive = false //dummy initialization
                    if isValid( prevCo) {
                        let prevPiece = pieces[prevCo.row][prevCo.col]
                        if prevPiece != .none {
                            if self.color == prevPiece {
                                col += 1
                                continue
                            } else {
                                headBlocked = true
                            }
                        } else {
                            let prev2Co = Coordinate(col: prevCo.col - 1, prevCo.row - 1)
                            if isValid( prev2Co) && pieces[prev2Co.row][prev2Co.col] == self.color {
                                repetitive = true
                            }
                            headBlocked = false
                        }
                    }
                    
                    var gaps = 0, gapsBuff = 0, same = 1, tailBlocked = false, i = 1
                    while(i <= 5) {
                        let nextCo = Coordinate(col: col + i, row: row + i)
                        if isValid( nextCo) {
                            let next = pieces[nextCo.row][nextCo.col]
                            if next != .none {
                                if next == currentPiece {
                                    gaps += gapsBuff
                                    same += 1
                                    gapsBuff = 0
                                } else {
                                    tailBlocked = true
                                    break
                                }
                            } else {
                                gapsBuff += 1
                            }
                        } else {
                            tailBlocked = true
                            break
                        }
                        i += 1
                    }
                    
                    if !repetitive || (same == 5 && gaps == 0) {
                        counter.interpret(headBlocked, tailBlocked, i, same, gaps)
                    }
                }
                col += 1
            }
            row += 1
        }
    }
    
    private func diagnalInspectionUrll() {
        var row = dim - 5
        while row >= 0 {
            var col = dim - 1
            while col >= 4 {
                let currentPiece = pieces[row][col]
                if currentPiece == self.color {
                    let prevCo = Coordinate(col: col + 1, row: row - 1)
                    var headBlocked: Bool = false, repetitive = false // special case
                    if isValid( prevCo) {
                        let prevPiece = pieces[prevCo.row][prevCo.col]
                        if prevPiece != .none {
                            if self.color == prevPiece {
                                col -= 1
                                continue
                            } else {
                                headBlocked = true
                            }
                        } else {
                            let prev2Co = Coordinate(col: prevCo.col + 1, prevCo.row - 1)
                            if isValid( prev2Co) && pieces[prev2Co.row][prev2Co.col] == self.color {
                                repetitive = true
                            }
                            headBlocked = false
                        }
                    }
                    
                    var gaps = 0, gapsBuff = 0, same = 1, tailBlocked = false, i = 1
                    while(i <= 5) {
                        let nextCo = Coordinate(col: col - i, row: row + i)
                        if isValid( nextCo) {
                            let next = pieces[nextCo.row][nextCo.col]
                            if next != .none {
                                if next == currentPiece {
                                    gaps += gapsBuff
                                    same += 1
                                    gapsBuff = 0
                                } else {
                                    tailBlocked = true
                                    break
                                }
                            } else {
                                gapsBuff += 1
                            }
                        } else {
                            tailBlocked = true
                            break
                        }
                        i += 1
                    }
                    if !repetitive || (same == 5 && gaps == 0) {
                        counter.interpret(headBlocked, tailBlocked, i, same, gaps)
                    }
                }
                col -= 1
            }
            row -= 1
        }
    }
    
    
    
    func isValid(_ co: Coordinate) -> Bool {
        return co.col >= 0 && co.row >= 0 && co.row < dim && co.col < dim
    }
    
    /**
     Wholistic linear evaluation
     - Returns: a score that represents the value of the board for a specific player
     */
    func evaluate(for player: Piece) -> Int {
        dim = pieces.count
        color = player
        counter = Counter()
            
        horizontalInspection()  //horizontal inspection
        verticalInspection()    //vertical inspection
        diagnalInspectionUllr() //diagnal inspection upper left to lower right
        diagnalInspectionUrll() //diagnal inspection upper right to lower left
        
        return counter.fives * ThreatType.five.rawValue
            + counter.freeFour * ThreatType.straightFour.rawValue
            + counter.freeThree * ThreatType.straightThree.rawValue
            + counter.freeTwo * ThreatType.straightTwo.rawValue
            
            + counter.blockedFour * ThreatType.blockedFour.rawValue
            + counter.blockedThree * ThreatType.blockedThree.rawValue
            + counter.blockedTwo * ThreatType.blockedTwo.rawValue
            
            + counter.blockedPokedFour * ThreatType.blockedPokedFour.rawValue
            + counter.freePokedFour * ThreatType.straightPokedFour.rawValue
            
            + counter.freePokedThree * ThreatType.straightPokedThree.rawValue
            + counter.blockedPokedThree * ThreatType.blockedPokedThree.rawValue
        // Missing straight poked 2
    }
}

protocol HeuristicEvaluatorDelegate {
    var pieces: [[Piece]] {get}
}

class Counter {
    // Fives
    var fives = 0
    var pokedFives = 0
    
    // Fours
    var blockedFour = 0
    var freeFour = 0
    var freePokedFour = 0
    var blockedPokedFour = 0
    
    // Threes
    var blockedThree = 0
    var freeThree = 0
    var freePokedThree = 0
    var blockedPokedThree = 0
    
    // Twos
    var freeTwo = 0
    var blockedTwo = 0
    
    var freeOne = 0
    
    func interpret(_ leftBlocked: Bool, _ rightBlocked: Bool, _ i: Int, _ same: Int, _ gaps: Int) {
        if (leftBlocked && rightBlocked && i <= 4) { //no potential
            return
        }
        switch gaps {
        case 0:
            switch same {
            case 5: fives += 1
            case 4:
                if leftBlocked {
                    if i >= 5  {
                        blockedFour += 1
                    }
                } else if rightBlocked {
                    if i >= 5  {
                        freeFour += 1
                    } else if i >= 4 {
                        blockedFour += 1
                    }
                } else {
                    freeFour += 1
                }
            case 3:
                if leftBlocked {
                    if i >= 4  {
                        blockedThree += 1
                    }
                } else if rightBlocked {
                    if i >= 4  {
                        freeThree += 1
                    } else if i >= 3 {
                        blockedThree += 1
                    }
                } else {
                    freeThree += 1
                }
            case 2: //debug
                if leftBlocked || rightBlocked {
                    blockedTwo += 1
                } else {
                    freeTwo += 1
                }
            case 1 where !leftBlocked && !rightBlocked: freeOne += 1
            default: break
            }
        case 1:
            switch same {
            case 5: pokedFives += 1
            case 4:
                if leftBlocked || rightBlocked {
                    blockedPokedFour += 1
                } else {
                    freePokedFour += 1
                }
            case 3:
                if leftBlocked || rightBlocked {
                    blockedPokedThree += 1
                } else {
                    freePokedThree += 1
                }
            default: break
            }
            
        default: break
        }
    }
    
}
