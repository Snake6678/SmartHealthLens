import Foundation
import CoreVideo
import Accelerate
import Combine

final class HeartRateEstimator: ObservableObject {
    @Published var heartRateBPM: Double = 0
    @Published var lastSignalWindowNormalized: [Float] = []
    
    private var samples: [Float] = []
    private let windowSeconds: Double = 20.0
    private let sampleRate: Double = 30.0 // approx front camera FPS
    
    var heartRateText: String {
        heartRateBPM > 0 ? String(format: "%.0f", heartRateBPM) : "--"
    }
    
    func processFrame(pixelBuffer: CVPixelBuffer) {
        let g = SignalProcessor.meanGreen(pixelBuffer: pixelBuffer)
        samples.append(g)
        
        let maxCount = Int(windowSeconds * sampleRate)
        if samples.count > maxCount {
            samples.removeFirst(samples.count - maxCount)
        }
        
        // Once we have enough samples, run FFT to estimate HR
        if samples.count >= maxCount / 2 {
            estimateHR()
        }
    }
    
    private func estimateHR() {
        var x = samples
        // Detrend & normalize
        let mean = x.reduce(0, +) / Float(x.count)
        vDSP_vsbsm(x, 1, [mean], [1.0], &x, 1, vDSP_Length(x.count))
        
        var rms: Float = 0
        vDSP_rmsqv(x, 1, &rms, vDSP_Length(x.count))
        if rms > 1e-6 {
            var norm = [Float](repeating: 0, count: x.count)
            vDSP_vsdiv(x, 1, [rms], &norm, 1, vDSP_Length(x.count))
            lastSignalWindowNormalized = norm
        } else {
            lastSignalWindowNormalized = x
        }
        
        // Zero-pad to next power of two
        let n = 1 << Int(ceil(log2(Double(x.count))))
        var re = x + [Float](repeating: 0, count: n - x.count)
        var im = [Float](repeating: 0, count: n)
        
        var setup = vDSP_DFT_zop_CreateSetup(nil, vDSP_Length(n), .FORWARD)!
        vDSP_DFT_Execute(setup, re, im, &re, &im)
        vDSP_DFT_DestroySetup(setup)
        
        // Magnitude spectrum
        var mag = [Float](repeating: 0, count: n/2)
        re.withUnsafeBufferPointer { rp in
            im.withUnsafeBufferPointer { ip in
                vDSP.absolute(rp.baseAddress!, ip.baseAddress!, result: &mag)
            }
        }
        
        // Frequency axis
        let df = Float(sampleRate) / Float(n)
        // Search 0.7–4.0 Hz (~42–240 bpm)
        let fMin: Float = 0.7
        let fMax: Float = 4.0
        let iMin = max(1, Int(fMin / df))
        let iMax = min(mag.count - 1, Int(fMax / df))
        
        if iMax > iMin {
            let slice = mag[iMin...iMax]
            if let maxIdx = slice.enumerated().max(by: { $0.element < $1.element })?.offset {
                let idx = iMin + maxIdx
                let freq = Float(idx) * df
                let bpm = Double(freq * 60.0)
                DispatchQueue.main.async {
                    self.heartRateBPM = bpm.isFinite ? bpm : 0
                }
            }
        }
    }
}
