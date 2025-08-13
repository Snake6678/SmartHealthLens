import SwiftUI

struct ContentView: View {
    @EnvironmentObject var hrEstimator: HeartRateEstimator
    @EnvironmentObject var sensorManager: SensorManager
    
    var body: some View {
        VStack(spacing: 16) {
            Text("SmartHealthLens")
                .font(.largeTitle).bold()
            
            CameraView(onFrame: { pixelBuffer in
                hrEstimator.processFrame(pixelBuffer: pixelBuffer)
            })
            .frame(height: 300)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(radius: 6)
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    MetricCard(title: "Heart Rate", value: hrEstimator.heartRateText, subtitle: "bpm")
                    MetricCard(title: "Cadence", value: String(format: "%.0f", sensorManager.stepCadence), subtitle: "spm")
                }
                SignalPlot(samples: hrEstimator.lastSignalWindowNormalized)
                    .frame(height: 80)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal)
            
            Spacer()
        }
        .padding()
        .onAppear {
            sensorManager.start()
        }
        .onDisappear {
            sensorManager.stop()
        }
    }
}

struct MetricCard: View {
    let title: String
    let value: String
    let subtitle: String
    
    init(title: String, value: String, subtitle: String) {
        self.title = title
        self.value = value
        self.subtitle = subtitle
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(title).font(.caption).foregroundColor(.secondary)
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(value).font(.system(size: 28, weight: .bold, design: .rounded))
                Text(subtitle).font(.footnote).foregroundColor(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct SignalPlot: View {
    let samples: [Float]
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let n = max(samples.count, 1)
            Path { path in
                for (i, s) in samples.enumerated() {
                    let x = CGFloat(i) / CGFloat(n - 1) * w
                    let y = h * 0.5 - CGFloat(s) * (h * 0.45)
                    if i == 0 { path.move(to: CGPoint(x: x, y: y)) }
                    else { path.addLine(to: CGPoint(x: x, y: y)) }
                }
            }
            .stroke(Color.primary.opacity(0.8), lineWidth: 2)
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(HeartRateEstimator())
        .environmentObject(SensorManager())
}
