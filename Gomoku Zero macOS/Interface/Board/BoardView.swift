//
//  BoardView.swift
//  Gomoku Zero
//
//  Created by Jiachen Ren on 10/5/18.
//  Copyright © 2018 Jiachen Ren. All rights reserved.
//  swiftlint:disable type_body_length file_length

import Cocoa
import CoreGraphics

@IBDesignable class BoardView: NSView {
    
    @IBInspectable var pieceScale: CGFloat = 0.95
    @IBInspectable var vertexColor: NSColor = .black
    @IBInspectable var zeroPlusThemeColor: NSColor = .yellow
    
    ///Vertices for 19 x 19
    var goVertices: [Coordinate] = [(3, 3), (15, 3), (3, 15), (15, 15), (9, 9), (9, 15), (15, 9), (9, 3), (3, 9)]
    
    /// Vertices for 15 x 15
    var gomokuVertices: [Coordinate] = [(3, 3), (11, 3), (3, 11), (11, 11), (7, 7)]
    
    weak var delegate: BoardViewDelegate?
    weak var dataSource: BoardViewDataSource?
    
    var pendingPieceCo: Coordinate?
    
    var activeMap: [[Bool]]? {
        didSet {
            updateDisplay()
        }
    }
    
    var zpHistory: History? {
        didSet {
            updateDisplay()
        }
    }
    
    // Wether track mouse is moving within the area of the board
    var mouseInScope = false
    
    var activeMapVisible = false
    var visualizationEnabled = true
    var historyVisible = true
    var showCalcDuration = false
    var drawsPendingPiece = true
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
            updateDisplay()
        }
    }
    
    let blackPieceImg = NSImage(named: "black_piece_shadowed")
    let whitePieceImg = NSImage(named: "white_piece_shadowed")
    let blackWithAlpha = NSImage(named: "black_piece_alpha")
    let whiteWithAlpha = NSImage(named: "white_piece_alpha")

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        self.wantsLayer = true
        
        // Draw board gird lines
        NSColor.black.withAlphaComponent(0.5).setStroke()
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
            let piece = pieces[co.row][co.col]
            let color: NSColor = piece == .black ? .green : .red
            color.withAlphaComponent(0.8).setStroke()
            if board.zeroIsThinking && showCalcDuration { // Display time lapsed
                let sec = Int(Date().timeIntervalSince1970 - board.calcStartTime)
                drawDigitOverlay(num: sec, for: piece, at: co, colorful: true)
            } else {
                var rect = self.rect(at: co)
                rect = CGRect(center: CGPoint(x: rect.midX, y: rect.midY),
                              size: CGSize(width: rect.width / 4, height: rect.height / 4))
                let path = NSBezierPath(rect: rect)
                path.lineWidth = gridLineWidth
                path.lineJoinStyle = .round
                path.stroke()
            }
        }
    }
    
    private func rect(at co: Coordinate) -> CGRect {
        return CGRect(center: onScreen(co),
                      size: CGSize(width: pieceRadius * 2, height: pieceRadius * 2))
    }
    
    private func highlightWinningCoordinates() {
        winningCoordinates?.forEach {
            var rect = self.rect(at: $0)
            rect = CGRect(center: CGPoint(x: rect.midX, y: rect.midY),
                          size: CGSize(width: rect.width / 4, height: rect.height / 4))
            let dot = NSBezierPath(ovalIn: rect)
            let color: NSColor = pieces[$0.row][$0.col] == .black ? .green : .red
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
            .font: NSFont.systemFont(ofSize: radius),
            .foregroundColor: piece == .black ? colorful ? NSColor.green : NSColor.white : colorful ? .red : .black
        ]
        var ctr = onScreen(co)
        ctr.y += radius / 8
        let textRect = CGRect(center: ctr, size: CGSize(width: pieceRadius * 2, height: radius))
        let attrString = NSAttributedString(string: "\(num)", attributes: attributes)
        attrString.draw(in: textRect)
    }
    
    private func drawZeroPlusHistory() {
        if let history = zpHistory {
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
                    let color: NSColor = board.curPlayer == .black ? .black : .white
                    color.withAlphaComponent(0.5).setFill()
                    let path = NSBezierPath(ovalIn: rect)
                    path.lineWidth = gridLineWidth
                    path.fill() // Should stroke look better?
                }
            }
        }
    }
    
    /**
     Convert the absolute position of the mouse to relative coordinate within the bounds
     - Returns: position of the mouse within bounds
     */
    private func relPos(evt: NSEvent) -> CGPoint {
        let absPos = evt.locationInWindow
        return CGPoint(x: absPos.x - frame.minX, y: absPos.y - frame.minY)
    }
    
    override func mouseUp(with event: NSEvent) {
        let pos = relPos(evt: event)
        if pos.x <= 0 || pos.y <= 0 || board.zeroIsThinking {
            // When users drag and release out side of the board area or user interaction disabled, do nothing.
            return
        }
        delegate?.didMouseUpOn(co: onBoard(pos))
    }
    
    override func mouseEntered(with event: NSEvent) {
        mouseInScope = true
        redrawPendingCo()
    }
    
    override func mouseExited(with event: NSEvent) {
        mouseInScope = false
        redrawPendingCo()
    }
    
    private func redrawPendingCo() {
        if let co = pendingPieceCo, drawsPendingPiece {
            setNeedsDisplay(rect(at: co))
        }
    }
    
    /**
     When the cursor moves within the active board area, erase the old pending move indicator
     and draw a new one at the new coordinate.
     */
    override func mouseMoved(with event: NSEvent) {
        let curCo = onBoard(relPos(evt: event))
        if drawsPendingPiece {
            if let co = pendingPieceCo {
                setNeedsDisplay(rect(at: co)) // Erase old pending piece
                if curCo != co {
                    // Draw pending piece at new coordinate
                    setNeedsDisplay(rect(at: curCo))
                }
            }
            pendingPieceCo = curCo // Update pending coordinate
        }
    }
    
    /// Render the board in detail when live resize is finished
    override func viewDidEndLiveResize() {
        setNeedsDisplay(bounds)
    }
    
    /// Activates tracking, otherwise mouseMoved, mouseEntered, mouseExited wouldn't be called.
    override func updateTrackingAreas() {
        for trackingArea in self.trackingAreas {
            self.removeTrackingArea(trackingArea)
        }
        let options: NSTrackingArea.Options = [.mouseEnteredAndExited, .activeAlways, .mouseMoved]
        let trackingArea = NSTrackingArea(rect: self.bounds, options: options, owner: self, userInfo: nil)
        self.addTrackingArea(trackingArea)
    }
    
    /// Draw a half transparent piece at the coordinate that the mouse is hovering over
    private func drawPendingPiece() {
        if let co = pendingPieceCo, mouseInScope {
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
    
    /// Draw the arrangement of black and white pieces on the board
    private func drawPieces() {
        for row in 0..<pieces.count {
            for col in 0..<pieces[row].count {
                let ctr = onScreen(Coordinate(col: col, row: row))
                let rect = CGRect(center: ctr, size: CGSize(width: pieceRadius * 2, height: pieceRadius * 2))
                if inLiveResize && pieces[row][col] != .none { // Draw an approximation to speed up drawing when resizing
                    (pieces[row][col] == .white ? NSColor.white : NSColor.black).setFill()
                    CGContext.fillCircle(center: ctr, radius: pieceRadius)
                } else {
                    switch pieces[row][col] {
                    case .black:blackPieceImg?.draw(in: rect)
                    case .white:whitePieceImg?.draw(in: rect)
                    case .none: break
                    }
                }
            }
        }
    }
    
    /**
     - Returns: NSBezierPath for the gird lines (default is 19 x 19)
     */
    private func pathForGrid() -> NSBezierPath {
        let path = NSBezierPath()
        path.move(to: CGPoint(x: cornerOffset, y: cornerOffset))
        (0..<dim).map {CGFloat($0)}.forEach {
            //draw the vertical lines
            path.move(to: CGPoint(x: cornerOffset + $0 * gap, y: cornerOffset))
            path.line(to: CGPoint(x: cornerOffset + $0 * gap, y: bounds.height - cornerOffset))
            
            //draw the horizontal lines
            path.move(to: CGPoint(x: cornerOffset, y: cornerOffset + $0 * gap))
            path.line(to: CGPoint(x: bounds.width - cornerOffset, y: cornerOffset + $0 * gap))
        }
        path.lineWidth = self.gridLineWidth
        path.lineCapStyle = .round
        return path
    }
    
    /// Draw the 9 strategic points on the go board
    private func drawVertices() {
        self.vertexColor.setFill()
        let vertices = board.dimension == 15 ? gomokuVertices : goVertices
        vertices.map {onScreen($0)}.forEach {
            CGContext.fillCircle(center: $0, radius: vertexRadius)
        }
    }
    
    /// Convert a coordinate to position on screen
    public func onScreen(_ coordinate: Coordinate) -> CGPoint {
        return CGPoint(
            x: cornerOffset + CGFloat(coordinate.col) * gap,
            y: bounds.height - (cornerOffset + CGFloat(coordinate.row) * gap)
        )
    }
    
    /// Convert a position on screen to coordinate
    public func onBoard(_ onScreen: CGPoint) -> Coordinate {
        func convert(_ n: CGFloat) -> Int {
            return Int((n - cornerOffset) / gap + 0.5)
        }
        return (convert(onScreen.x), dim - convert(onScreen.y) - 1)
    }
    
    /// Mark the view as outdated and update in the main thread
    public func updateDisplay() {
        DispatchQueue.main.async {[unowned self] in
            self.setNeedsDisplay(self.bounds)
        }
    }
}

// Getters
extension BoardView {
    var gridLineWidth: CGFloat {
        return gap / 20
    }
    
    var pieceRadius: CGFloat {
        return gap / 2 * pieceScale
    }
    
    var vertexRadius: CGFloat {
        return gridLineWidth * 2
    }
    
    var boardWidth: CGFloat {
        return self.bounds.width - cornerOffset * 2
    }
    
    var gap: CGFloat {
        return self.bounds.width / CGFloat(dim)
    }
    
    var board: Board {
        return dataSource?.board ?? Board(dimension: 15)
    }
    
    var dim: Int {
        return board.dimension
    }
    
    var pieces: [[Piece]] {
        return board.pieces
    }
    
    var cornerOffset: CGFloat {
        return gap / 2
    }
}

protocol BoardViewDelegate: AnyObject {
    func didMouseUpOn(co: Coordinate)
}

protocol BoardViewDataSource: AnyObject {
    var board: Board {get}
}
