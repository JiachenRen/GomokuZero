//
//  main.swift
//  Gomoku Zero Model
//
//  Created by Jiachen Ren on 12/8/18.
//  Copyright © 2018 Jiachen Ren. All rights reserved.
//

import Foundation

class GameState: BoardDelegate {
    var board: Board
    
    init(_ board: Board) {
        self.board = board
        board.delegate = self
    }
    
    func boardDidUpdate(pieces: [[Piece]]) {
        print("\n\(board)", terminator: "\n\n")
    }
    
    func gameHasEnded(winner: Piece, coordinates: [Coordinate], popDialogue: Bool) {
        print(winner == .black ? "Black wins!" : "White wins!")
    }
    
    func beginGameLoop() {
        board.requestZeroBrainStorm()
        while true {
            Thread.sleep(forTimeInterval: 0.1)
            var shouldExit = false
            input: while !board.zeroIsThinking && !shouldExit {
                shouldExit = true
                print("Your move (row, column): ")
                let line = readLine()!
                switch line {
                case "restart": board.restart()
                case "undo": board.undo()
                case "redo": board.redo()
                case "exit": exit(0)
                default:
                    let co = line.split(separator: ",").map {Int($0)}
                    if co.count == 2 && !co.contains {$0 == nil} {
                        let coordinate = (co.last!! - 1, co.first!! - 1)
                        if isValid(coordinate, board.dimension) {
                            board.put(at: coordinate)
                            print("Thinking...")
                        } else {
                            print("Coordinate out of bounds.")
                            shouldExit = false
                        }
                    } else {
                        print("Invalid format.")
                        shouldExit = false
                    }
                }
            }
        }
    }
}

print("Gomoku Zero Copyright (c) 2018. Designed by Jiachen Ren. All Rights Reserved.\n")

// Choose board dimension
print("Please enter board dimension:")
let dim = Int(readLine()!)!
let board = Board(dimension: dim)
let gameState = GameState(board)

// Choose color
print("Choose color (b/w):")
let c = readLine()!
if c == "b" {
    print("\n\(board)", terminator: "\n\n")
    board.zeroIdentity = .white
} else {
    board.zeroIdentity = .black
}

// Begin!
gameState.beginGameLoop()
