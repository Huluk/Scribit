//
//  LineSegment.swift
//  Scribit
//
//  Created by Lars Hansen on 2016-01-01.
//  Copyright © 2016 Lars Hansen. All rights reserved.
//

class LineSegment : NSObject,NSCoding {
    let archivePressureKey = "archiveLineSegmentPressureKey"
    
    var start: NSPoint
    var end: NSPoint
    var firstControlPoint: NSPoint
    var secondControlPoint: NSPoint
    var pressure: Float
    var bounds: NSRect!
    
    init(start: NSPoint, end: NSPoint,
        controlPoint1: NSPoint, controlPoint2: NSPoint,
        pressure: Float)
    {
        self.start = start
        self.end = end
        self.firstControlPoint = controlPoint1
        self.secondControlPoint = controlPoint2
        self.pressure = pressure
        super.init()
        self.calculateBounds()
    }
    
    convenience init(lineSegment s: LineSegment) {
        self.init(start: s.start, end: s.end,
            controlPoint1: s.firstControlPoint, controlPoint2: s.secondControlPoint,
            pressure: s.pressure)
    }
    
    convenience init(start: NSPoint, end: NSPoint, pressure: Float) {
        self.init(start: start, end: end,
            controlPoint1: start, controlPoint2: end,
            pressure: pressure)
    }

    required init(coder decoder: NSCoder) {
        start = decoder.decodePoint()
        end = decoder.decodePoint()
        firstControlPoint = decoder.decodePoint()
        secondControlPoint = decoder.decodePoint()
        pressure = decoder.decodeFloatForKey(archivePressureKey)
        super.init()
        calculateBounds()
    }
    
    func calculateBounds() {
        let x = [start.x, end.x, firstControlPoint.x, secondControlPoint.x]
        let y = [start.y, end.y, firstControlPoint.y, secondControlPoint.y]
        let minX = x.minElement()!
        let minY = y.minElement()!
        bounds = NSMakeRect(minX, minY, x.maxElement()!-minX, y.maxElement()!-minY)
    }
        
    func encodeWithCoder(coder: NSCoder) {
        coder.encodePoint(start)
        coder.encodePoint(end)
        coder.encodePoint(firstControlPoint)
        coder.encodePoint(secondControlPoint)
        coder.encodeFloat(pressure, forKey:archivePressureKey)
    }
}