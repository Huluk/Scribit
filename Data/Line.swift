//
//  Line.swift
//  Scribit
//
//  Created by Lars Hansen on 2015-12-29.
//  Copyright © 2015 Lars Hansen. All rights reserved.
//

import Cocoa

class Line: NSObject, NSCoding {
    let GetX = 0;
    let GetY = 1;

    var segments = [LineSegment]()
    var color: NSColor
    
    init(color: NSColor) {
        self.color = color
    }
    
    required init(coder: NSCoder) {
        let codedSegments = coder.decodeObject() as! [LineSegment.CodingHelper]
        self.segments = codedSegments.map {$0.get()}
        self.color = coder.decodeObject() as! NSColor
    }
    
    func encodeWithCoder(coder: NSCoder) {
        coder.encodeObject(segments.map {LineSegment.CodingHelper(segment: $0)})
        coder.encodeObject(color)
    }
    
    func addSegment(segment: LineSegment) {
        segments.append(segment)
    }
    
    func bezierPath() -> NSBezierPath {
        let path = NSBezierPath()
        path.lineCapStyle = NSLineCapStyle.RoundLineCapStyle
        for segment in segments {
            path.moveToPoint(segment.start)
            path.curveToPoint(segment.end,
                controlPoint1: segment.firstControlPoint, controlPoint2: segment.secondControlPoint)
        }
        return path
    }
    
    // Algorithm by Oleg V. Polikarpotchkin and Peter Lee, 24 Mar 2009
    // http://www.codeproject.com/Articles/31859/Draw-a-Smooth-Curve-through-a-Set-of-D-Points-wit
    // Objective-C port by Lars Hansen, 19 Oct 2014
    // Swift port by Lars Hansen, 01 Jan 2016
    // TODO make continuous version (update while drawing)
    func interpolateCurves() {
        let n = segments.count
        if (n < 1) {
            NSException(name: "empty line", reason:"line \(self) has no segments!",
                userInfo:nil).raise()
        }
        if (n == 1) { return }
        
        var firstControlPoints = getFirstControlPoints()
        for (var i = 0; i < n; i++) {
            var secondControlPoint: NSPoint
            if (i + 1 < n) {
                let nextPoint = segments[i+1].start
                secondControlPoint = NSMakePoint(2 * nextPoint.x - firstControlPoints[i+1].x,
                    2 * nextPoint.y - firstControlPoints[i+1].y)
            } else {
                let nextPoint = segments.last!.end
                secondControlPoint = NSMakePoint((nextPoint.x + firstControlPoints[n-1].x) / 2,
                    (nextPoint.y + firstControlPoints[n-1].y) / 2)
            }
            segments[i].firstControlPoint = firstControlPoints[i]
            segments[i].secondControlPoint = secondControlPoint
        }
        // TODO update bounds rect, after having such a thing in the first place
    }
    
    private func getFirstControlPoints() -> [NSPoint] {
        let n = segments.count
        var firstControlPoints = Array<NSPoint>(count: n, repeatedValue: NSPoint())
        var x = getFirstControlPointsForOneCoord(GetX)
        var y = getFirstControlPointsForOneCoord(GetY)
        for (var i = 0; i < n; i++) {
            firstControlPoints[i] = NSMakePoint(x[i], y[i]);
        }
        return firstControlPoints
    }
    
    private func getFirstControlPointsForOneCoord(coord: Int) -> [CGFloat] {
        let p = getKnotCoord(coord)
        let rhs = getRHSVectorFromOneCoord(p)
        return getOneCoordOfFirstControlPoints(rhs)
    }
    
    private func getKnotCoord(coord: Int) -> [CGFloat] {
        let n = segments.count
        var knotsCoord = Array<CGFloat>(count: n+1, repeatedValue: CGFloat.NaN)
        var loc: NSPoint
        for (var i = 0; i < n; ++i) {
            loc = segments[i].start
            knotsCoord[i] = coord == GetX ? loc.x : loc.y
        }
        loc = segments.last!.end
        knotsCoord[n] = coord == GetX ? loc.x : loc.y
        return knotsCoord
    }
    
    private func getRHSVectorFromOneCoord(coords: [CGFloat]) -> [CGFloat] {
        let n = segments.count
        var rhs = Array<CGFloat>(count: n, repeatedValue: CGFloat.NaN)
        for (var i = 1; i + 1 < n; i++) {
            rhs[i] = 4 * coords[i] + 2 * coords[i + 1];
        }
        rhs[0] = coords[0] + 2 * coords[1];
        rhs[n - 1] = (8 * coords[n - 1] + coords[n]) / 2.0;
        return rhs
    }
    
    private func getOneCoordOfFirstControlPoints(rhs: [CGFloat]) -> [CGFloat] {
        let n = segments.count
        var x = Array<CGFloat>(count: n, repeatedValue: CGFloat.NaN)
        var tmp = Array<CGFloat>(count: n, repeatedValue: CGFloat.NaN)
        var b:CGFloat = 2.0;
        x[0] = rhs[0] / b;
        for (var i = 1; i < n; i++) { // Decomposition and forward substitution.
            tmp[i] = 1 / b;
            b = (i < n - 1 ? 4.0 : 3.5) - tmp[i];
            x[i] = (rhs[i] - x[i - 1]) / b;
        }
        for (var i = 1; i < n; i++) {
            x[n - i - 1] -= tmp[n - i] * x[n - i]; // Backsubstitution.
        }
        return x
    }
}
