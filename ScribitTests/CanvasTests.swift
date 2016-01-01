//
//  ScribitTests.swift
//  ScribitTests
//
//  Created by Lars Hansen on 2015-12-29.
//  Copyright © 2015 Lars Hansen. All rights reserved.
//

import XCTest
@testable import Scribit

class CanvasTests: XCTestCase {
    
    var canvas: Canvas!
    
    override func setUp() {
        super.setUp()
        canvas = Canvas(frame: NSMakeRect(0,0,300,200))
        canvas.document = Document()
        canvas.document.canvas = canvas
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testAddLine() {
        let event = NSEvent.mouseEventWithType(.MouseMoved, location: NSPoint(), modifierFlags: [], timestamp: NSTimeInterval(), windowNumber: 0, context: nil, eventNumber: 0, clickCount: 0, pressure: 0.0)
        XCTAssertEqual(canvas.currentPage().lines.count, 0)
        canvas.mouseDown(event!)
        XCTAssertEqual(canvas.currentPage().lines.count, 1)
        canvas.document.undoManager?.undo()
        XCTAssertEqual(canvas.currentPage().lines.count, 0)
    }
    
}
