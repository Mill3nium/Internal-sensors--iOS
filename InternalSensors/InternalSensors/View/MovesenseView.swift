import SwiftUI
import SwiftUICharts

struct MovesenseView: View {
    @EnvironmentObject var vm : InternalSensorVM
    @StateObject var manager = SensorManager()
    
    var body: some View {
        VStack {
            if manager.connectedSensor == nil {
                Text("Select sensor to connect")
                List(Array(manager.discoveredSensors.values)) { sensor in
                    Button(sensor.peripheral.name!) {
                        sensor.connect()
                    }
                }
                .task {
                    manager.startDiscovery()
                }
            } else {
                let sensor = manager.connectedSensor!
                
                Text("Connected to \(sensor.peripheral.name!)")
                Button("Disconnect") {
                    sensor.disconnect()
                }
                .frame(width: 120, height: 40, alignment: .center)
                .background(Color.red)
                .foregroundColor(.white)
                .cornerRadius(8)
                
                let x = String(format: "x 🔴: %.2f", manager.last20ax[manager.last20ax.count-1])
                let y = String(format: "y 🟢: %.2f", manager.last20ay[manager.last20ay.count-1])
                let z = String(format: "z 🔵: %.2f", manager.last20az[manager.last20az.count-1])
                MultiLineChartView(
                    data: manager.chartData,
                    title: "Acceleration",
                    legend: "\(x), \(y), \(z)",
                    form: ChartForm.large
                )
                
            }
        }
    }
}
