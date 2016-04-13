//
//  LineTest.swift
//  Scribit
//
//  Created by Lars Hansen on 2016-04-13.
//  Copyright © 2016 Lars Hansen. All rights reserved.
//

import XCTest
@testable import Scribit

class MockSegment : LineSegment {
    let intersects: Bool
    
    init(_ intersect: Bool) {
        intersects = intersect
        super.init(start: NSPoint(), end: NSPoint(),
                   controlPoint1: NSPoint(), controlPoint2: NSPoint(),
                   pressure: 1.0)
    }
    
    required init(coder decoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func intersectsRect(rect: NSRect) -> Bool {
        return intersects
    }
}

class LineTest: XCTestCase {
    
    var line: Line!

    override func setUp() {
        super.setUp()
        line = Line(brush: Brush.defaultPen)
    }

    func testIntersectingSegmentRanges() {
        let (inside: a, outside: b) = line.intersectingSegmentRanges(NSRect()) // no segments
        XCTAssertTrue(a.isEmpty)
        XCTAssertTrue(b.isEmpty)
        line.segments = [0, 1, 1, 1, 0, 1, 1, 0].map{MockSegment($0 == 1)}
        var (inside: inside, outside: outside) = line.intersectingSegmentRanges(NSRect())
        XCTAssertEqual([1...3, 5...6], inside)
        XCTAssertEqual([0...0, 4...4, 7..<8], outside)
        line.segments = [1, 1, 1].map{ MockSegment($0 == 1) }
        (inside: inside, outside: outside) = line.intersectingSegmentRanges(NSRect())
        XCTAssertEqual([0..<3], inside)
        XCTAssertTrue(outside.isEmpty)
    }
}
