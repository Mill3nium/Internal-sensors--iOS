import SwiftUI
import SwiftUICharts

struct MovesenseView: View {
    @EnvironmentObject var vm : InternalSensorVM
    @StateObject var movesense = MovesenseVM()
    
    var body: some View {
        VStack {
            if movesense.connectedSensor == nil {
                Text("Select sensor to connect")
                List(Array(movesense.discoveredSensors.values)) { sensor in
                    Button(sensor.peripheral.name!) {
                        sensor.connect()
                    }
                }
                .task {
                    movesense.startDiscovery()
                }
            } else {
                let sensor = movesense.connectedSensor!
                
                Text("Connected to \(sensor.peripheral.name!)")
                Button("Disconnect") {
                    sensor.disconnect()
                }
                .frame(width: 120, height: 40, alignment: .center)
                .background(Color.red)
                .foregroundColor(.white)
                .cornerRadius(8)
                
                let x = String(format: "x 🔴: %.2f", movesense.last20ax[movesense.last20ax.count-1])
                let y = String(format: "y 🟢: %.2f", movesense.last20ay[movesense.last20ay.count-1])
                let z = String(format: "z 🔵: %.2f", movesense.last20az[movesense.last20az.count-1])
                MultiLineChartView(
                    data: movesense.chartData,
                    title: "Acceleration",
                    legend: "\(x), \(y), \(z)",
                    form: ChartForm.large
                )
            }
        }
    }
}
