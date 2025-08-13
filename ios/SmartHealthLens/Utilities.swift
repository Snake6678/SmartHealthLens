import Foundation

extension Array where Element == Float {
    func normalized() -> [Float] {
        guard let minV = self.min(), let maxV = self.max(), maxV > minV else { return self }
        let range = maxV - minV
        return self.map { ($0 - minV) / range * 2 - 1 }
    }
}
