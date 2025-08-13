import SwiftUI

@main
struct SmartHealthLensApp: App {
    @StateObject private var sensorManager = SensorManager()
    @StateObject private var hrEstimator = HeartRateEstimator()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(sensorManager)
                .environmentObject(hrEstimator)
        }
    }
}
