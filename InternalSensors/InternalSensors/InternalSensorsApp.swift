import SwiftUI


@main
struct InternalSensorsApp: App {
    @StateObject private var theViewModel = InternalSensorVM()
    
    var body: some Scene {
        WindowGroup {
            SensorTabsView()
                .environmentObject(theViewModel)
        }
    }
}
