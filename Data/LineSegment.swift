//
//  LineSegment.swift
//  Scribit
//
//  Created by Lars Hansen on 2016-01-01.
//  Copyright © 2016 Lars Hansen. All rights reserved.
//

struct LineSegment {
    var start: NSPoint
    var end: NSPoint
    var firstControlPoint: NSPoint
    var secondControlPoint: NSPoint
    var pressure: Float
    
    init(start: NSPoint, end: NSPoint,
        controlPoint1: NSPoint, controlPoint2: NSPoint,
        pressure: Float)
    {
        self.start = start
        self.end = end
        self.firstControlPoint = controlPoint1
        self.secondControlPoint = controlPoint2
        self.pressure = pressure
    }
    
    init(start: NSPoint, end: NSPoint, pressure: Float) {
        self.init(start: start, end: end,
            controlPoint1: start, controlPoint2: end,
            pressure: pressure)
    }
    
    class CodingHelper: NSObject,NSCoding {
        let archivePressureKey = "archiveLineSegmentPressureKey"
        
        var start: NSPoint
        var end: NSPoint
        var firstControlPoint: NSPoint
        var secondControlPoint: NSPoint
        var pressure: Float
        
        init(segment: LineSegment) {
            start = segment.start
            end = segment.end
            firstControlPoint = segment.firstControlPoint
            secondControlPoint = segment.secondControlPoint
            pressure = segment.pressure
        }
        
        required init?(coder decoder: NSCoder) {
            start = decoder.decodePoint()
            end = decoder.decodePoint()
            firstControlPoint = decoder.decodePoint()
            secondControlPoint = decoder.decodePoint()
            pressure = decoder.decodeFloatForKey(archivePressureKey)
        }
        
        func encodeWithCoder(coder: NSCoder) {
            coder.encodePoint(start)
            coder.encodePoint(end)
            coder.encodePoint(firstControlPoint)
            coder.encodePoint(secondControlPoint)
            coder.encodeFloat(pressure, forKey:archivePressureKey)
        }
        
        func get() -> LineSegment {
            return LineSegment(start: start, end: end,
                controlPoint1: firstControlPoint, controlPoint2: secondControlPoint,
                pressure: pressure)
        }
    }
}