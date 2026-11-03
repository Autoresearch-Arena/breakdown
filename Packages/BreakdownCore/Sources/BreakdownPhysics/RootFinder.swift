// Author: Claude Sonnet 5.5 Medium
// Date: 03-November-2026
// PURPOSE: Find the first time a polynomial (degree four at most) crosses from positive to negative, which is
//          how every contact time is found (ball-ball and ball-pocket are quartics, ball-cushion a quadratic).
//          Roots are isolated by recursing on the derivative so intervals are monotone, then bisected for a
//          fixed iteration count. Only add, subtract, multiply and divide are used: fully deterministic.
// SRP/DRY check: Pass - the single root finder used by every event type.

enum RootFinder {
    static func evaluate(_ c: [Double], _ t: Double) -> Double {
        var r = 0.0
        var i = c.count - 1
        while i >= 0 { r = r * t + c[i]; i -= 1 }
        return r
    }

    private static func derivative(_ c: [Double]) -> [Double] {
        var d: [Double] = []
        var i = 1
        while i < c.count { d.append(c[i] * Double(i)); i += 1 }
        return d
    }

    /// Smallest t in [0, limit] where the polynomial passes from positive to non-positive, or nil.
    /// Requires the value at zero to be positive; callers handle already-touching cases themselves.
    static func firstDownCrossing(_ coefficients: [Double], limit: Double) -> Double? {
        var c = coefficients
        while c.count > 1, c[c.count - 1] == 0 { c.removeLast() }
        if c.count < 2 { return nil }
        if evaluate(c, 0) <= 0 { return nil }
        let turning = turningPoints(c, limit)
        var points = [0.0]
        for t in turning where t > 0 && t < limit { points.append(t) }
        points.append(limit)
        var i = 0
        while i + 1 < points.count {
            let a = points[i], b = points[i + 1]
            let fa = evaluate(c, a), fb = evaluate(c, b)
            if fa > 0, fb <= 0 { return bisect(c, a, b) }
            i += 1
        }
        return nil
    }

    /// Sorted points in (0, limit) where the polynomial's derivative is zero (its turning points).
    private static func turningPoints(_ c: [Double], _ limit: Double) -> [Double] {
        let d = derivative(c)
        return allRoots(d, limit)
    }

    /// All sign-change roots of a polynomial in [0, limit], sorted.
    private static func allRoots(_ coefficients: [Double], _ limit: Double) -> [Double] {
        var c = coefficients
        while c.count > 1, c[c.count - 1] == 0 { c.removeLast() }
        if c.count < 2 { return [] }
        if c.count == 2 {
            let r = -c[0] / c[1]
            return (r > 0 && r < limit) ? [r] : []
        }
        var points = [0.0]
        for t in allRoots(derivative(c), limit) { points.append(t) }
        points.append(limit)
        var out: [Double] = []
        var i = 0
        while i + 1 < points.count {
            let a = points[i], b = points[i + 1]
            let fa = evaluate(c, a), fb = evaluate(c, b)
            if (fa < 0 && fb >= 0) || (fa > 0 && fb <= 0) { out.append(bisect(c, a, b)) }
            i += 1
        }
        return out
    }

    /// Fixed 80-step bisection followed by two Newton polish steps clamped to the bracket.
    private static func bisect(_ c: [Double], _ lo0: Double, _ hi0: Double) -> Double {
        var lo = lo0, hi = hi0
        let flo = evaluate(c, lo)
        var step = 0
        while step < 80 {
            let mid = (lo + hi) * 0.5
            let fm = evaluate(c, mid)
            if (fm > 0) == (flo > 0) { lo = mid } else { hi = mid }
            step += 1
        }
        var t = (lo + hi) * 0.5
        let d = derivative(c)
        var n = 0
        while n < 2 {
            let slope = evaluate(d, t)
            if slope != 0 {
                let next = t - evaluate(c, t) / slope
                if next >= lo0 && next <= hi0 { t = next }
            }
            n += 1
        }
        return t
    }
}
