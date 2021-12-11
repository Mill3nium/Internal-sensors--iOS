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
                .frame(alignment: .center)
                .padding(10)
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
                
                Button(movesense.recording ? "Stop recording" : "Start recording") {
                    movesense.recording ? movesense.stopRecording() : movesense.startRecording()
                }
                .frame(alignment: .center)
                .padding(15)
                .background(movesense.recording ? Color.red : Color.green)
                .foregroundColor(.white)
                .cornerRadius(8)
                .fileExporter(
                    isPresented: $movesense.showingExporter,
                    document: movesense.csvFile,
                    contentType: .commaSeparatedText,
                    defaultFilename: "movesense.csv"
                ){ result in
                    switch result {
                    case .success(let url):
                        print("Saved to \(url)")
                    case .failure(let error):
                        print(error.localizedDescription)
                    }
                    
                    movesense.showingExporter = false
                }
                
            }
        }
    }
}
