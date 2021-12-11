import SwiftUI



struct SensorTabsView: View {
    var body: some View{
        TabView{
            InternalSensorsView().tabItem{
                Image(systemName: "lines.measurement.horizontal")
                Text("Internal")
            }
            MovesenseView().tabItem {
                Image(systemName: "sensor.tag.radiowaves.forward")
                Text("Movesense")
            }
        }
    }
}
