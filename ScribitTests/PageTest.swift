//
//  PageTest.swift
//  Scribit
//
//  Created by Lars Hansen on 2016-04-13.
//  Copyright © 2016 Lars Hansen. All rights reserved.
//

import XCTest
@testable import Scribit

class MockLine : Line {
    let layer: Int
    convenience init(_ layer: Int) {
        self.init(layer: layer, segments: [])
    }
    convenience init(segments: [Int]) {
        self.init(layer: 0, segments: segments)
    }
    init(layer: Int, segments boolSegs: [Int]) {
        self.layer = layer
        let segments = boolSegs.map { MockSegment($0==1) }
        let brush = Brush(name: "", color: NSColor.blackColor(),
                          size: 0, type: BrushType(rawValue: layer)!)
        super.init(brush: brush, segments: segments, transform: NSAffineTransform())
    }
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    override func defaultLayer() -> Int { return layer }
}

class PageTest: XCTestCase {
    
    var page: Page!
    
    override func setUp() {
        super.setUp()
        page = Page(pageRect: NSRect(), backgroundColor: NSColor.blackColor())
    }
    
    func testAddAndDeleteLine() {
        let line0 = MockLine(0)
        let line0b = MockLine(0)
        let line3 = MockLine(3)
        page.addLine(line0)
        XCTAssertEqual([[line0], [], [], []], page.lines)
        page.addLine(line3)
        XCTAssertEqual([[line0], [], [], [line3]], page.lines)
        page.addLine(line0, crop: true)
        XCTAssertEqual([[line0], [line0], [], [line3]], page.lines)
        page.addLine(line0b, crop: false)
        XCTAssertEqual([[line0, line0b], [line0], [], [line3]], page.lines)
        
        XCTAssertEqual([line0, line0b, line0, line3], Array<Line>(page.allLines()))
        page.deleteLine(line0)
        let sort_exp = { (l1:Line, l2:Line) in "\(l1)" < "\(l2)" }
        XCTAssertEqual([line0, line0b, line3].sort(sort_exp), page.allLines().sort(sort_exp))
        page.deleteLine(line0)
        XCTAssertEqual([[line0b], [], [], [line3]], page.lines)
    }
    
    func testCropLine() {
        // single line
        let lineA = MockLine(0)
        let lineB = MockLine(0)
        let lineC = MockLine(2)
        page.lines = [[lineA], [lineB], [], [lineC]]
        page.uncropLine(lineB)
        XCTAssertEqual([[lineA, lineB], [], [], [lineC]], page.lines)
        page.cropLine(lineA)
        let expectedLines = [[lineB], [lineA], [], [lineC]]
        XCTAssertEqual(expectedLines, page.lines)
        
        // uncrop all + undo
        let undoManager = NSUndoManager()
        page.uncropAll(undoManager: undoManager)
        XCTAssertEqual([[lineB, lineA], [], [lineC], []], page.lines)
        undoManager.undo()
        XCTAssertEqual(expectedLines, page.lines)
    }
    
    func testAddSplits() {
        let line = MockLine(segments: [1,1,1,0,0])
        let undoManager = NSUndoManager()
        page.addSplits(line, [0..<3], crop: true, undoManager: undoManager)
        XCTAssertEqual(1, page.allLines().count)
        XCTAssertEqual(3, page.lines[1][0].segments.count)
        XCTAssertEqual([true, true, true], page.lines[1][0].segments.map{$0.intersectsRect(NSRect())})
    }
    
    func testCrop() {
        let lineIn = MockLine(layer: 0, segments: [1])
        let lineHalf = MockLine(layer: 2, segments: [1, 1, 1, 0, 0 ,0, 0])
        let lineOut = MockLine(layer: 2, segments: [0])
        let lineExtra = MockLine(0)
        page.lines = [[lineIn], [lineExtra], [lineOut, lineHalf], []]
        let undoManager = NSUndoManager()
        page.crop(rect: NSRect(), undoManager: undoManager)
        XCTAssertTrue(page.lines[0].isEmpty)
        XCTAssertEqual([lineExtra, lineIn], page.lines[1])
        XCTAssertEqual(2, page.lines[2].count)
        XCTAssertEqual(lineOut, page.lines[2][0])
        XCTAssertEqual(4, page.lines[2][1].segments.count)
        XCTAssertEqual(1, page.lines[3].count)
        XCTAssertEqual(3, page.lines[3][0].segments.count)
    }
}
