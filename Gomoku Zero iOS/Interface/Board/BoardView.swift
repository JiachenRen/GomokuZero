//
//  BoardView.swift
//  Gomoku Zero iOS
//
//  Created by Jiachen Ren on 11/25/18.
//  Copyright © 2018 Jiachen Ren. All rights reserved.

import UIKit

@IBDesignable class BoardView: UIView {
    
    @IBInspectable var pieceScale: CGFloat = 0.95
    
    @IBInspectable var vertexColor: UIColor = .black
    @IBInspectable var zeroPlusThemeColor: UIColor = .yellow
    
    /// Vertices for 19 x 19
    var goVertices: [Coordinate] = [(3, 3), (15, 3), (3, 15), (15, 15), (9, 9), (9, 15), (15, 9), (9, 3), (3, 9)]
    
    /// Vertices for 15 x 15
    var gomokuVertices: [Coordinate] = [(3, 3), (11, 3), (3, 11), (11, 11), (7, 7)]
    
    var pendingPieceCo: Coordinate?
    
    weak var dataSource: BoardViewDataSource?
    var activeMap: [[Bool]]? {
        didSet {
            updateDisplay()
        }
    }
    
    var zeroPlusHistory: History? {
        didSet {
            updateDisplay()
        }
    }
    
    var drawsPendingPiece = true
    var activeMapVisible = true
    var visualizationEnabled = false
    var historyVisible = true
    var showCalcDuration = false
    var highlightLastStep = true {
        didSet {
            if let co = board.history.stack.last {
                setNeedsDisplay(rect(at: co))
            }
        }
    }
    var overlayStepNumber = false {
        didSet {
            updateDisplay()
        }
    }
    
    var winningCoordinates: [Coordinate]? {
        didSet {
            updateDisplay()
        }
    }
    
    let blackPieceImg = UIImage(named: "black_piece_shadowed")
    let whitePieceImg = UIImage(named: "white_piece_shadowed")
    let blackWithAlpha = UIImage(named: "black_piece_alpha")
    let whiteWithAlpha = UIImage(named: "white_piece_alpha")
    
    override func draw(_ dirtyRect: CGRect) {
        super.draw(dirtyRect)
        
        if BoardViewConfig.solidBgd {
            UIColor(red: 1, green: 0.807, blue: 0.35, alpha: 0.5)
                .withAlphaComponent(BoardViewConfig.bgdAlpha)
                .setFill()
            if BoardViewConfig.roundedCorner {
                UIBezierPath(roundedRect: bounds, cornerRadius: cornerRadius).fill()
            } else {
                UIBezierPath(rect: bounds).fill()
            }
        }
        
        // Draw board gird lines
        UIColor.black.setStroke()
        pathForGrid().stroke()
        
        if board.dimension == 19 || board.dimension == 15 {
            drawVertices()
        }
        
        drawPieces()
        
        if !board.zeroIsThinking && !board.gameHasEnded {
            drawPendingPiece()
        }
        
        if visualizationEnabled {
            if activeMapVisible {
                drawActiveMap()
            }
            if historyVisible {
                drawZeroPlusHistory()
            }
        }
        
        if overlayStepNumber {
            drawStepNumberOverlay()
        } else {
            if board.gameHasEnded {
                highlightWinningCoordinates()
            } else if highlightLastStep {
                highlightMostRecentStep()
            }
        }
    }
    
    func rect(at co: Coordinate) -> CGRect {
        return CGRect(center: onScreen(co),
                      size: CGSize(width: pieceRadius * 2, height: pieceRadius * 2))
    }
    
    private func highlightMostRecentStep() {
        if let co = board.history.stack.last {
            let piece = pieces[co.row][co.col]
            let color: UIColor = piece == .black ? .green : .red
            color.withAlphaComponent(0.8).setStroke()
            if board.zeroIsThinking && showCalcDuration { // Display time lapsed
                let sec = Int(Date().timeIntervalSince1970 - board.calcStartTime)
                drawDigitOverlay(num: sec, for: piece, at: co, colorful: true)
            } else {
                var rect = self.rect(at: co)
                rect = CGRect(center: CGPoint(x: rect.midX, y: rect.midY),
                              size: CGSize(width: rect.width / 4, height: rect.height / 4))
                let path = UIBezierPath(rect: rect)
                path.lineWidth = gridLineWidth
                path.lineJoinStyle = .round
                path.stroke()
            }
        }
    }
    
    private func highlightWinningCoordinates() {
        winningCoordinates?.forEach {
            var rect = self.rect(at: $0)
            rect = CGRect(center: CGPoint(x: rect.midX, y: rect.midY),
                          size: CGSize(width: rect.width / 4, height: rect.height / 4))
            let dot = UIBezierPath(ovalIn: rect)
            let color: UIColor = pieces[$0.row][$0.col] == .black ? .green : .red
            color.withAlphaComponent(0.8).setFill()
            dot.fill()
        }
    }
    
    private func drawStepNumberOverlay() {
        var color: Piece = .black
        for (num, co) in board.history.stack.enumerated() {
            drawDigitOverlay(num: num + 1, for: color, at: co, colorful: num == board.history.stack.count - 1)
            color = color.next()
        }
    }
    
    private func drawDigitOverlay(num: Int, for piece: Piece, at co: Coordinate, colorful: Bool) {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        let radius = pieceRadius / 4 * 3
        let attributes = [
            NSAttributedString.Key.paragraphStyle: paragraphStyle,
            .font: UIFont.systemFont(ofSize: radius),
            .foregroundColor: piece == .black ? colorful ? UIColor.green : UIColor.white : colorful ? .red : .black
            ]
        var ctr = onScreen(co)
        //        ctr.x += pieceRadius / 4
        ctr.y -= radius / 8
        let textRect = CGRect(center: ctr, size: CGSize(width: pieceRadius * 2, height: radius))
        let attrString = NSAttributedString(string: "\(num)", attributes: attributes)
        attrString.draw(in: textRect)
    }
    
    private func drawZeroPlusHistory() {
        if let history = zeroPlusHistory {
            var player = board.curPlayer
            for (col, row) in history.stack {
                let ctr = onScreen(Coordinate(col: col, row: row))
                let rect = CGRect(center: ctr, size: CGSize(width: pieceRadius * 2, height: pieceRadius * 2))
                switch player {
                case .black:
                    blackWithAlpha?.draw(in: rect)
                case .white:
                    whiteWithAlpha?.draw(in: rect)
                case .none: break
                }
                player = player.next()
            }
        }
    }
    
    var dampenerMap: [[CGFloat]] = [[CGFloat]](repeating: [CGFloat](repeating: 0, count: 19), count: 19)
    
    func updateDampenerMap() {
        activeMap?.enumerated().forEach { (r, row) in
            row.enumerated().forEach { (c, b) in
                let i = dampenerMap[r][c]
                if i < 1 && b {
                    dampenerMap[r][c] += 0.03
                } else if i > 0 {
                    dampenerMap[r][c] -= 0.03
                }
            }
        }
    }
    
    private func drawActiveMap() {
        guard let map = self.activeMap else {
            return
        }
        updateDampenerMap()
        for row in 0..<map.count {
            for col in 0..<map[row].count {
                let ctr = onScreen(Coordinate(col: col, row: row))
                let scale = dampenerMap[row][col]
                var radius = pieceRadius
                radius *= scale
                let rect = CGRect(center: ctr, size: CGSize(width: radius, height: radius))
                if scale > 0 {
                    let color: UIColor = board.curPlayer == .black ? .black : .white
                    color.withAlphaComponent(0.5).setFill()
                    let path = UIBezierPath(ovalIn: rect)
                    path.lineWidth = gridLineWidth
                    path.fill() // Should stroke look better?
                }
            }
        }
    }
    
    private func redrawPendingCo() {
        if let co = pendingPieceCo, drawsPendingPiece {
            setNeedsDisplay(rect(at: co))
        }
    }
    
    /**
     Draw a half transparent piece at the coordinate that the mouse is hovering over
     */
    private func drawPendingPiece() {
        if let co = pendingPieceCo {
            if !isValid(co, dim) { return }
            if pieces[co.row][co.col] == .none { // If the coordinate is not occupied
                let rect = self.rect(at: co)
                if board.curPlayer == .black {
                    blackWithAlpha?.draw(in: rect)
                } else {
                    whiteWithAlpha?.draw(in: rect)
                }
            }
        }
    }
    
    /**
     Draw the arrangement of black and white pieces on the board
     */
    private func drawPieces() {
        for row in 0..<pieces.count {
            for col in 0..<pieces[row].count {
                let ctr = onScreen(Coordinate(col: col, row: row))
                let rect = CGRect(center: ctr, size: CGSize(width: pieceRadius * 2, height: pieceRadius * 2))
                switch pieces[row][col] {
                case .black:blackPieceImg?.draw(in: rect)
                case .white:whitePieceImg?.draw(in: rect)
                case .none: break
                }
            }
        }
    }
    
    /**
     - Returns: NSBezierPath for the gird lines (default is 19 x 19)
     */
    private func pathForGrid() -> UIBezierPath {
        let path = UIBezierPath()
        path.move(to: CGPoint(x: cornerOffset, y: cornerOffset))
        (0..<dim).map {CGFloat($0)}.forEach {
            //draw the vertical lines
            path.move(to: CGPoint(x: cornerOffset + $0 * gap, y: cornerOffset))
            path.addLine(to: CGPoint(x: cornerOffset + $0 * gap, y: bounds.height - cornerOffset))
            
            //draw the horizontal lines
            path.move(to: CGPoint(x: cornerOffset, y: cornerOffset + $0 * gap))
            path.addLine(to: CGPoint(x: bounds.width - cornerOffset, y: cornerOffset + $0 * gap))
        }
        path.lineWidth = self.gridLineWidth
        path.lineCapStyle = .round
        return path
    }
    
    /**
     Draw the 9 strategic points on the go board
     */
    private func drawVertices() {
        self.vertexColor.setFill()
        let vertices = board.dimension == 15 ? gomokuVertices : goVertices
        vertices.map {onScreen($0)}.forEach {
            CGContext.fillCircle(center: $0, radius: vertexRadius)
        }
    }
    
    /**
     Convert a coordinate to position on screen
     */
    public func onScreen(_ coordinate: Coordinate) -> CGPoint {
        return CGPoint(
            x: cornerOffset + CGFloat(coordinate.col) * gap,
            y: bounds.height - (cornerOffset + CGFloat(coordinate.row) * gap)
        )
    }
    
    /**
     Convert a position on screen to coordinate
     */
    public func onBoard(_ onScreen: CGPoint) -> Coordinate {
        func convert(_ n: CGFloat) -> Int {
            return Int((n - cornerOffset) / gap + 0.5)
        }
        return (convert(onScreen.x), dim - convert(onScreen.y) - 1)
    }
    
    func updateDisplay() {
        DispatchQueue.main.async {[unowned self] in
            self.setNeedsDisplay(self.bounds)
        }
    }
}

/// Getters
extension BoardView {
    var gridLineWidth: CGFloat {
        return gap / 30
    }
    
    var pieceRadius: CGFloat {
        return gap / 2 * pieceScale
    }
    
    var vertexRadius: CGFloat {
        return gap / 10
    }
    
    var boardWidth: CGFloat {
        return self.bounds.width - cornerOffset * 2
    }
    
    var gap: CGFloat {
        return self.bounds.width / (CGFloat(dim) + cornerOffsetScale * 2 - 1)
    }
    
    var dim: Int {
        return board.dimension
    }
    
    var pieces: [[Piece]] {
        return board.pieces
    }
    
    var board: Board {
        return dataSource?.board ?? Board(dimension: 19)
    }
    
    var cornerOffsetScale: CGFloat {
        return 0.7
    }
    
    var cornerOffset: CGFloat {
        return gap * cornerOffsetScale
    }
    
    var cornerRadius: CGFloat {
        return bounds.width * 1 / 20
    }
}

protocol BoardViewDataSource: AnyObject {
    var board: Board {get}
}

class BoardViewConfig {
    public static var solidBgd: Bool = true
    public static var bgdAlpha: CGFloat = 1
    public static var themeImage: UIImage = UIImage(named: "board_d")!
    public static var roundedCorner: Bool = true
}
