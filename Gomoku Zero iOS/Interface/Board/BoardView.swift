//
//  BoardView.swift
//  Gomoku Zero iOS
//
//  Created by Jiachen Ren on 11/25/18.
//  Copyright © 2018 Jiachen Ren. All rights reserved.
//

import UIKit

@IBDesignable class BoardView: UIView {
    
    @IBInspectable var pieceScale: CGFloat = 0.95
    
    @IBInspectable var vertexColor: UIColor = .black
    @IBInspectable var zeroPlusThemeColor: UIColor = .yellow
    
    var gridLineWidth: CGFloat {
        return gap / 20
    }
    
    var pieceRadius: CGFloat {
        return gap / 2 * pieceScale
    }
    
    var vertexRadius: CGFloat {
        return gridLineWidth * 2
    }
    
    /**
     Coordinates in the format of (row, column) of the standard vertices of a go board.
     For 19 x 19
     */
    var goVertices: [Coordinate] = {
        return [(3, 3), (15, 3), (3, 15), (15, 15), (9, 9), (9, 15), (15, 9), (9, 3), (3, 9)]
    }()
    
    /**
     Vertices for 15 x 15
     */
    var gomokuVertices: [Coordinate] = {
        return [(3, 3), (11, 3), (3, 11), (11, 11), (7, 7)]
    }()
    
    var boardWidth: CGFloat {
        return self.bounds.width - cornerOffset * 2
    }
    
    var gap: CGFloat {
        return self.bounds.width / CGFloat(dimension)
    }
    
    var dimension: Int = 19 {
        didSet {
            DispatchQueue.main.async {[unowned self] in
                self.setNeedsDisplay(self.bounds)
            }
            dampenerMap = [[CGFloat]] (repeating: [CGFloat](repeating: 0, count: dimension), count: dimension)
        }
    }
    
    var pieces: [[Piece]]? {
        didSet {
            // If the pieces passed in is nill, the dimension should remain unchanged
            dimension = pieces?.count ?? dimension
        }
    }
    
    var board: Board {
        return delegate?.board ?? Board(dimension: 19)
    }
    
    var cornerOffset: CGFloat {
        return gap / 2
    }
    
    var pendingPieceCo: Coordinate?
    var shouldDrawPendingPiece = true
    func rect(at co: Coordinate) -> CGRect {
        return CGRect(center: onScreen(co),
                      size: CGSize(width: pieceRadius * 2, height: pieceRadius * 2))
    }
    
    var delegate: BoardViewDelegate?
    var activeMap: [[Bool]]? {
        didSet {
            setNeedsDisplay(bounds)
        }
    }
    
    var zeroPlusHistory: History? {
        didSet {
            setNeedsDisplay(bounds)
        }
    }
    
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
            setNeedsDisplay(bounds)
        }
    }
    
    var winningCoordinates: [Coordinate]? {
        didSet {
            DispatchQueue.main.async {[unowned self] in
                self.setNeedsDisplay(self.bounds)
            }
        }
    }
    
    let blackPieceImg = UIImage(named: "black_piece_shadowed")
    let whitePieceImg = UIImage(named: "white_piece_shadowed")
    let blackWithAlpha = UIImage(named: "black_piece_alpha")
    let whiteWithAlpha = UIImage(named: "white_piece_alpha")
    
    override func draw(_ dirtyRect: CGRect) {
        super.draw(dirtyRect)
        
        // Draw board gird lines
        UIColor.black.withAlphaComponent(0.5).setStroke()
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
    
    private func highlightMostRecentStep() {
        if let co = board.history.stack.last {
            let piece = pieces![co.row][co.col]
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
            let color: UIColor = pieces![$0.row][$0.col] == .black ? .green : .red
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
        let attributes = [
            NSAttributedString.Key.paragraphStyle  : paragraphStyle,
            .font            : UIFont.systemFont(ofSize: pieceRadius),
            .foregroundColor : piece == .black ? colorful ? UIColor.green : UIColor.white : colorful ? .red : .black,
            ]
        var ctr = onScreen(co)
        //        ctr.x += pieceRadius / 4
        ctr.y -= pieceRadius / 8
        let textRect = CGRect(center: ctr, size: CGSize(width: pieceRadius * 2, height: pieceRadius))
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
                radius = radius * scale
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
        if let co = pendingPieceCo, shouldDrawPendingPiece {
            setNeedsDisplay(rect(at: co))
        }
    }
    
    /**
     Draw a half transparent piece at the coordinate that the mouse is hovering over
     */
    private func drawPendingPiece() {
        if let co = pendingPieceCo {
            if !isValid(co, dimension) { return }
            if pieces == nil || pieces![co.row][co.col] == .none { // If the coordinate is not occupied
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
        guard let pieces = self.pieces else {
            return
        }
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
        (0..<dimension).map{CGFloat($0)}.forEach{
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
        vertices.map{onScreen($0)}.forEach {
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
        return (convert(onScreen.x), dimension - convert(onScreen.y) - 1)
    }
}

protocol BoardViewDelegate {
    var board: Board {get}
}
