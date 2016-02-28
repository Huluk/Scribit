//
//  Line.swift
//  Scribit
//
//  Created by Lars Hansen on 2015-12-29.
//  Copyright © 2015 Lars Hansen. All rights reserved.
//

import Cocoa

class Line: NSObject, NSCoding {
    // number of line segments which are used to calculate the current bezier path while drawing
    let concurrentDrawingContext = 3
    
    var segments = [LineSegment]()
    var brush: Brush
    var type:BrushType { return brush.type }
    var coordTransformLocalToGlobal: NSAffineTransform
    private(set) var final = false
    
    init(brush: Brush) {
        self.brush = brush
        self.coordTransformLocalToGlobal = NSAffineTransform()
    }
    
    required init(coder: NSCoder) {
        self.segments = coder.decodeObject() as! [LineSegment]
        self.brush = coder.decodeObject() as! Brush
        self.coordTransformLocalToGlobal = coder.decodeObject() as! NSAffineTransform
    }
    
    func encodeWithCoder(coder: NSCoder) {
        coder.encodeObject(segments)
        coder.encodeObject(brush)
        coder.encodeObject(coordTransformLocalToGlobal)
    }
    
    func addSegment(segment: LineSegment) {
        segments.append(segment)
        let n = segments.count
        let start_n = n - concurrentDrawingContext
        var newestSegments = Array(segments[max(0,start_n)..<n])
        if (start_n > 0) {
            // do not modify the initial element if it is not start of line
            newestSegments[0] = LineSegment(lineSegment: newestSegments[0])
        }
        interpolateCurves(newestSegments)
    }
    
    func drawingContent(fromIndex startIndex: Int) -> [(NSColor, NSBezierPath, NSRect)] {
        var content = [(NSColor, NSBezierPath, NSRect)]()
        for segment in segments.suffixFrom(startIndex) {
            var path = NSBezierPath()
            path.lineCapStyle = .RoundLineCapStyle
            path.lineWidth = brush.sizeFromPressure(segment.pressure)
            segment.drawCurve(&path)
            content.append((brush.colorFromPressure(segment.pressure), path, segment.bounds))
        }
        return content
    }
    
    func finishDrawing() {
        let bounds = internalBounds()
        let center = NSMakePoint(NSMinX(bounds)+NSWidth(bounds)/2, NSMinY(bounds)+NSHeight(bounds)/2)
        coordTransformLocalToGlobal.translateXBy(center.x, yBy: center.y)
        let globalToLocal = NSAffineTransform(transform: coordTransformLocalToGlobal)
        globalToLocal.invert()
        for segment in segments {
            segment.start = globalToLocal.transformPoint(segment.start)
            segment.end = globalToLocal.transformPoint(segment.end)
        }
        interpolateCurves(segments) // implicitly takes care of control point transform
    }
    
    func internalBounds() -> NSRect {
        return segments.reduce(NSRect(), combine: {NSUnionRect($0, $1.bounds)})
    }
    
    func drawingBounds() -> NSRect {
        let drawingMargin = ceil(brush.widestSize / 2)
        let bounds = internalBounds()
        let drawingSize = coordTransformLocalToGlobal.transformSize(
            NSMakeSize(bounds.width+2*drawingMargin, bounds.height+2*drawingMargin))
        let drawingOrigin = coordTransformLocalToGlobal.transformPoint(
            NSMakePoint(bounds.origin.x-drawingMargin, bounds.origin.y-drawingMargin))
        return NSRect(origin: drawingOrigin, size: drawingSize)
    }
    
    var widestSize: CGFloat { return brush.widestSize }
    
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
