import SwiftUI


@main
struct InternalSensorsApp: App {
    @StateObject private var theViewModel = InternalSensorVM()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(theViewModel)
        }
    }
}
