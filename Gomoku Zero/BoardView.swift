//
//  BoardView.swift
//  Gomoku Zero
//
//  Created by Jiachen Ren on 10/5/18.
//  Copyright © 2018 Jiachen Ren. All rights reserved.
//

import Cocoa
import CoreGraphics

public typealias Coordinate = (col: Int, row: Int)

@IBDesignable class BoardView: NSView {
    
    @IBInspectable var pieceScale: CGFloat = 0.95

    @IBInspectable var vertexColor: NSColor = NSColor.black
    
    @IBInspectable var gridLineWidth: CGFloat {
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
     */
    static var vertices: [Coordinate] = {
        return [(3, 3), (15, 3), (3, 15), (15, 15), (9, 9), (9, 15), (15, 9), (9, 3), (3, 9)]
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
        }
    }
    
    var pieces: [[Piece]]? {
        didSet {
            // If the pieces passed in is nill, the dimension should remain unchanged
            dimension = pieces?.count ?? dimension
        }
    }
    
    var cornerOffset: CGFloat {
        return gap / 2
    }
    
    var delegate: BoardViewDelegate?
    
    let boardBackground = NSImage(named: "board_dark")
    let blackPieceImg = NSImage(named: "black_piece")
    let whitePieceImg = NSImage(named: "white_piece")

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        self.wantsLayer = true
        // Drawing code here.
        
        
        
        
        // Draw background wooden texture of the board
        boardBackground?.draw(in: dirtyRect)
        
        // Fill board background
        let outerRect = CGRect(origin: dirtyRect.origin, size: dirtyRect.size)
        NSColor(red: 0.839, green: 0.706, blue: 0.412, alpha: 0.5).setFill()
        outerRect.fill()
        
        // Draw board gird lines
        NSColor.black.withAlphaComponent(0.5).setStroke()
        pathForGrid().stroke()
        
        // Draw vertices
        drawVertices()
        
        drawPieces()
        
        
    }
    
    override func mouseUp(with event: NSEvent) {
        let absPos = event.locationInWindow
        let relPos = CGPoint(x: absPos.x - frame.minX, y: absPos.y - frame.minY)
        if relPos.x <= 0 || relPos.y <= 0 {
            // When users drag and release out side of the board area, do nothing.
            return
        }
        delegate?.didMouseUpOn(co: onBoard(relPos))
    }
    
    private func drawPieces() {
        guard let pieces = self.pieces else {
            return
        }
        for row in 0..<pieces.count {
            for col in 0..<pieces[row].count {
                let ctr = onScreen(Coordinate(col: col, row: row))
                let rect = CGRect(center: ctr, size: CGSize(width: pieceRadius * 2, height: pieceRadius * 2))
                switch pieces[row][col] {
                case .black: blackPieceImg?.draw(in: rect)
                case .white: whitePieceImg?.draw(in: rect)
                case .none: break
                }
            }
        }
    }
    
    private func pathForGrid() -> NSBezierPath {
        let path = NSBezierPath()
        path.move(to: CGPoint(x: cornerOffset, y: cornerOffset))
        (0..<dimension).map{CGFloat($0)}.forEach{
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
    
    private func drawVertices() {
        self.vertexColor.setFill()
        BoardView.vertices.map{onScreen($0)}.forEach {
            CGContext.fillCircle(center: $0, radius: vertexRadius)
        }
    }
    
    /**
     Convert a coordinate to position on screen
     */
    private func onScreen(_ coordinate: Coordinate) -> CGPoint {
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
    func didMouseUpOn(co: Coordinate)
}

extension CGContext {
    static func point(at point: CGPoint, strokeWeight: CGFloat){
        let circle = NSBezierPath(ovalIn: CGRect(center: point, size: CGSize(width: strokeWeight, height: strokeWeight)))
        circle.fill()
    }
    static func fillCircle(center: CGPoint, radius: CGFloat) {
        let circle = NSBezierPath(ovalIn: CGRect(center: center, size: CGSize(width: radius * 2, height: radius * 2)))
        circle.fill()
    }
}

extension CGRect {
    init(center: CGPoint, size: CGSize){
        self.init(
            origin: CGPoint(
                x: center.x - size.width / 2,
                y: center.y - size.height / 2
            ),
            size: size
        )
    }
    static func fillCircle(center: CGPoint, radius: CGFloat) {
        let circle = NSBezierPath(ovalIn: CGRect(center: center, size: CGSize(width: radius * 2, height: radius * 2)))
        circle.fill()
    }
}
