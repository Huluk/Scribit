//
//  LineSegment.swift
//  Scribit
//
//  Created by Lars Hansen on 2016-01-01.
//  Copyright © 2016 Lars Hansen. All rights reserved.
//

enum PointToRectangleRelation : Int {
    case
    Inside = 0,
    Left = 1,
    Right = 2,
    Below = 4,
    Above = 8,
    // combinations
    LeftAndRight = 3,
    LeftAndBelow = 5,
    RightAndBelow = 6,
    LeftAndAbove = 9,
    RightAndAbove = 10,
    AboveAndBelow = 12
}

func | (left: PointToRectangleRelation, right: PointToRectangleRelation) -> PointToRectangleRelation {
    return PointToRectangleRelation(rawValue: left.rawValue | right.rawValue)!
}
func & (left: PointToRectangleRelation, right: PointToRectangleRelation) -> PointToRectangleRelation {
    return PointToRectangleRelation(rawValue: left.rawValue & right.rawValue)!
}

class LineSegment : NSObject,NSCoding {
    let archivePressureKey = "archiveLineSegmentPressureKey"
    let smallValue:CGFloat = 0.00001
    
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
        super.init()
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
    }
    
    func drawCurve(inout path: NSBezierPath) {
        path.moveToPoint(start)
        path.curveToPoint(end,
            controlPoint1: firstControlPoint, controlPoint2: secondControlPoint)
    }
    
    var bounds: NSRect {
        let x = [start.x, end.x, firstControlPoint.x, secondControlPoint.x]
        let y = [start.y, end.y, firstControlPoint.y, secondControlPoint.y]
        let minX = x.minElement()!
        let minY = y.minElement()!
        let dX = x.maxElement()!-minX + smallValue
        let dY = y.maxElement()!-minY + smallValue
        return NSMakeRect(minX, minY, dX, dY)
    }
        
    func encodeWithCoder(coder: NSCoder) {
        coder.encodePoint(start)
        coder.encodePoint(end)
        coder.encodePoint(firstControlPoint)
        coder.encodePoint(secondControlPoint)
        coder.encodeFloat(pressure, forKey:archivePressureKey)
    }
    
    func intersectsRect(rect: NSRect) -> Bool {
        // TODO use splines instead of straight line
        // e.g. https://www.particleincell.com/2013/cubic-line-intersection/
        let startRelation = relation(start, toRect:rect)
        let endRelation = relation(end, toRect:rect)
        let bothRelations = startRelation | endRelation
    
        if (startRelation == .Inside || endRelation == .Inside) {
            return true
        } else if (startRelation & endRelation != .Inside) { // both are on one side
            return false
        } else if bothRelations == .LeftAndRight || bothRelations == .AboveAndBelow {
            return true
        } else { // diagonal difference
            if bothRelations == .LeftAndBelow || bothRelations == .RightAndAbove ||
                startRelation == .RightAndBelow || endRelation == .RightAndBelow ||
                startRelation == .LeftAndAbove || endRelation == .LeftAndAbove
            {
                return self.isBetween(rect.origin, and: NSMakePoint(NSMaxX(rect), NSMaxY(rect)))
            } else {
                return self.isBetween(NSMakePoint(NSMaxX(rect), NSMinY(rect)), and: NSMakePoint(NSMinX(rect), NSMaxY(rect)))
            }
        }
    }
    
    private func relation(point: NSPoint, toRect rect: NSRect) -> PointToRectangleRelation {
        var relation = PointToRectangleRelation.Inside;
        if point.x < NSMinX(rect) {
                relation = relation | .Left;
        } else if point.x > NSMaxX(rect) {
            relation = relation | .Right;
        }
        if point.y < NSMinY(rect) {
            relation = relation | .Below;
        } else if point.y > NSMaxY(rect) {
            relation = relation | .Above;
        }
        return relation
    }
    
    private func isBetween(a: NSPoint, and b: NSPoint) -> Bool {
        return self.sideOfPoint(a) + self.sideOfPoint(b) == 0;
    }
    
    private func sideOfPoint(point: NSPoint) -> Int {
        let side = ((end.x-start.x)*(point.y-start.y) - (end.y-start.y)*(point.x-start.x))
        return side >= 0 ? 1 : -1;
    }
}