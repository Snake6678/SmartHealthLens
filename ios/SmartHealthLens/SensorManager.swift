import Foundation
import CoreMotion

final class SensorManager: ObservableObject {
    private let pedometer = CMPedometer()
    @Published var stepCadence: Double = 0 // steps per minute
    
    func start() {
        guard CMPedometer.isPaceAvailable() else { return }
        pedometer.startUpdates(from: Date()) { data, error in
            guard let d = data, error == nil else { return }
            DispatchQueue.main.async {
                self.stepCadence = d.currentCadence?.doubleValue ?? 0 * 60.0
            }
        }
    }
    
    func stop() {
        pedometer.stopUpdates()
    }
}
