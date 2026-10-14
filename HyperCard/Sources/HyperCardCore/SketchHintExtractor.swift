import Foundation

public struct SketchHintExtractor {
    public init() {}

    public static func hints(from strokes: [[SketchPoint]]) -> SketchHint? {
        let all = strokes.flatMap { $0 }
        guard all.count >= 12 else { return nil }

        let minX = all.map(\.x).min() ?? 0
        let maxX = all.map(\.x).max() ?? 1
        let minY = all.map(\.y).min() ?? 0
        let maxY = all.map(\.y).max() ?? 1
        let spanX = max(maxX - minX, 0.0001)
        let spanY = max(maxY - minY, 0.0001)

        let normalized = all.map {
            SketchPoint(x: ($0.x - minX) / spanX, y: ($0.y - minY) / spanY)
        }

        let clusters = cluster(normalized)
        guard !clusters.isEmpty else { return nil }

        var rowCount = 0
        var hasTopImage = false
        var hasBottomButton = false

        for cluster in clusters {
            let minX = cluster.map(\.x).min() ?? 0
            let maxX = cluster.map(\.x).max() ?? 0
            let minY = cluster.map(\.y).min() ?? 0
            let maxY = cluster.map(\.y).max() ?? 0
            let width = maxX - minX
            let height = maxY - minY
            let centerY = (minY + maxY) / 2
            let size = max(width, height, 0.0001)

            if centerY > 0.72, height < 0.16, width > 0.3 {
                hasBottomButton = true
            } else if centerY < 0.3, abs(width - height) / size < 0.35, cluster.count >= 12 {
                hasTopImage = true
            } else if centerY >= 0.22, centerY <= 0.75 {
                rowCount += 1
            }
        }

        guard rowCount + (hasTopImage ? 1 : 0) + (hasBottomButton ? 1 : 0) >= 2 else { return nil }

        return SketchHint(rowCount: rowCount, hasTopImage: hasTopImage, hasBottomButton: hasBottomButton)
    }

    static func cluster(_ points: [SketchPoint]) -> [[SketchPoint]] {
        let count = points.count
        var parent = Array(0..<count)
        func find(_ i: Int) -> Int {
            var root = i
            while parent[root] != root { root = parent[root] }
            var cursor = i
            while parent[cursor] != root {
                let next = parent[cursor]
                parent[cursor] = root
                cursor = next
            }
            return root
        }
        func union(_ a: Int, _ b: Int) {
            let ra = find(a)
            let rb = find(b)
            if ra != rb { parent[rb] = ra }
        }

        let threshold = 0.09
        for i in 0..<count {
            for j in (i + 1)..<count {
                let dx = points[i].x - points[j].x
                let dy = points[i].y - points[j].y
                if sqrt(dx * dx + dy * dy) < threshold {
                    union(i, j)
                }
            }
        }

        var groups: [Int: [SketchPoint]] = [:]
        for i in 0..<count {
            groups[find(i), default: []].append(points[i])
        }
        return Array(groups.values)
    }
}
