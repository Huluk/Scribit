//
//  Line.swift
//  Scribit
//
//  Created by Lars Hansen on 2015-12-29.
//  Copyright © 2015 Lars Hansen. All rights reserved.
//

import Cocoa

class Line: NSObject, NSCoding {
    var segments = [LineSegment]()
    var brush: Brush
    var bounds = NSRect()
    
    init(brush: Brush) {
        self.brush = brush
    }
    
    required init(coder: NSCoder) {
        self.segments = coder.decodeObject() as! [LineSegment]
        self.brush = coder.decodeObject() as! Brush
        self.bounds = coder.decodeRect()
    }
    
    func encodeWithCoder(coder: NSCoder) {
        coder.encodeObject(segments)
        coder.encodeObject(brush)
        coder.encodeRect(bounds)
    }
    
    func addSegment(segment: LineSegment) {
        segments.append(segment)
        bounds = NSUnionRect(bounds, segment.bounds)
        let n = segments.count
        var newestSegments = Array(segments[max(0,n-5)..<n])
        newestSegments[0] = LineSegment(lineSegment: newestSegments[0])
        interpolateCurves(newestSegments)
    }
    
    func bezierPath() -> NSBezierPath {
        let path = NSBezierPath()
        path.lineCapStyle = brush.lineCapStyle
        path.lineWidth = brush.size
        for segment in segments {
            path.moveToPoint(segment.start)
            path.curveToPoint(segment.end,
                controlPoint1: segment.firstControlPoint, controlPoint2: segment.secondControlPoint)
        }
        return path
    }
    
    private func interpolateSegment(previous prev: NSPoint, inout segment: LineSegment, next: NSPoint)
    {
        segment.firstControlPoint = guessControl(prev, segment.start)
        segment.secondControlPoint = guessControl(next, segment.end)
    }
    
    private func guessControl(farPoint: NSPoint, _ closePoint: NSPoint) -> NSPoint {
        let dx = closePoint.x - farPoint.x
        let dy = closePoint.y - farPoint.y
        return NSMakePoint(closePoint.x + 0.25*dx, closePoint.y + 0.25*dy)
    }
    
    func interpolateCurves() {
        interpolateCurves(segments)
        bounds = NSRect()
        for segment in segments {
            segment.calculateBounds()
            bounds = NSUnionRect(bounds, segment.bounds)
        }
    }
    
    // Algorithm by Oleg V. Polikarpotchkin and Peter Lee, 24 Mar 2009
    // http://www.codeproject.com/Articles/31859/Draw-a-Smooth-Curve-through-a-Set-of-D-Points-wit
    // Objective-C port by Lars Hansen, 19 Oct 2014
    // Swift port by Lars Hansen, 01 Jan 2016
    // TODO make continuous version (update while drawing)
    private func interpolateCurves(segments: [LineSegment]) {
        let n = segments.count
        if (n < 1) {
            NSException(name: "empty line", reason:"line \(self) has no segments!",
                userInfo:nil).raise()
        }
        if (n == 1) { return }
        
        var firstControlPoints = getFirstControlPoints(segments)
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
    }
    
    private func getFirstControlPoints(segments: [LineSegment]) -> [NSPoint] {
        let n = segments.count
        var firstControlPoints = Array<NSPoint>(count: n, repeatedValue: NSPoint())
        var x, y : Array<CGFloat>
        x = segments.map{$0.start.x}
        y = segments.map{$0.start.y}
        x.append(segments.last!.end.x)
        y.append(segments.last!.end.y)
        x = getCoordOfFirstControlPoints(getRHSVector(x))
        y = getCoordOfFirstControlPoints(getRHSVector(y))
        for (var i = 0; i < n; i++) {
            firstControlPoints[i] = NSMakePoint(x[i], y[i]);
        }
        return firstControlPoints
    }
    
    private func getRHSVector(coords: [CGFloat]) -> [CGFloat] {
        let n = coords.count - 1
        var rhs = Array<CGFloat>(count: n, repeatedValue: CGFloat.NaN)
        for (var i = 1; i + 1 < n; i++) {
            rhs[i] = 4 * coords[i] + 2 * coords[i + 1]
        }
        rhs[0] = coords[0] + 2 * coords[1]
        rhs[n - 1] = (8 * coords[n - 1] + coords[n]) / 2.0
        return rhs
    }
    
    private func getCoordOfFirstControlPoints(rhs: [CGFloat]) -> [CGFloat] {
        let n = rhs.count
        var x = Array<CGFloat>(count: n, repeatedValue: CGFloat.NaN)
        var tmp = Array<CGFloat>(count: n, repeatedValue: CGFloat.NaN)
        var b:CGFloat = 2.0
        x[0] = rhs[0] / b
        for (var i = 1; i < n; i++) { // Decomposition and forward substitution.
            tmp[i] = 1 / b
            b = (i < n - 1 ? 4.0 : 3.5) - tmp[i]
            x[i] = (rhs[i] - x[i - 1]) / b
        }
        for (var i = 1; i < n; i++) {
            x[n - i - 1] -= tmp[n - i] * x[n - i] // Backsubstitution.
        }
        return x
    }
}
