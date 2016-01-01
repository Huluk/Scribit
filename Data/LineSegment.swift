//
//  LineSegment.swift
//  Scribit
//
//  Created by Lars Hansen on 2016-01-01.
//  Copyright © 2016 Lars Hansen. All rights reserved.
//

struct LineSegment {
    class CodingHelper: NSObject,NSCoding {
        let archivePressureKey = "archiveLineSegmentPressureKey"
        
        var start: NSPoint
        var end: NSPoint
        var pressure: Float
        
        init(segment: LineSegment) {
            start = segment.start
            end = segment.end
            pressure = segment.pressure
        }
        
        required init?(coder decoder: NSCoder) {
            start = decoder.decodePoint()
            end = decoder.decodePoint()
            pressure = decoder.decodeFloatForKey(archivePressureKey)
        }
        
        func encodeWithCoder(coder: NSCoder) {
            coder.encodePoint(start)
            coder.encodePoint(end)
            coder.encodeFloat(pressure, forKey:archivePressureKey)
        }
        
        func get() -> LineSegment {
            return LineSegment(start: start, end: end, pressure: pressure)
        }
    }
    
    var start: NSPoint
    var end: NSPoint
    var pressure: Float
    
    init(start: NSPoint, end: NSPoint, pressure: Float) {
        self.start = start
        self.end = end
        self.pressure = pressure
    }
}