import SwiftUI
import SwiftUICharts

struct MovesenseView: View {
    @StateObject var vm = MovesenseVM()
    
    var body: some View {
        VStack {
            if vm.connectedSensor == nil {
                Text("Select sensor to connect")
                List(Array(vm.discoveredSensors.values)) { sensor in
                    Button(sensor.peripheral.name!) {
                        sensor.connect()
                    }
                }
                .task {
                    vm.startDiscovery()
                }
            } else {
                let sensor = vm.connectedSensor!
                
                Text("Connected to \(sensor.peripheral.name!)")
                Button("Disconnect") {
                    sensor.disconnect()
                }
                .frame(alignment: .center)
                .padding(10)
                .background(Color.red)
                .foregroundColor(.white)
                .cornerRadius(8)
                
                let x = String(format: "x 🔴: %.2f", vm.last100ax[vm.last100ax.count-1])
                let y = String(format: "y 🟢: %.2f", vm.last100ay[vm.last100ay.count-1])
                let z = String(format: "z 🔵: %.2f", vm.last100az[vm.last100az.count-1])
                MultiLineChartView(
                    data: vm.chartData,
                    title: "Acceleration",
                    legend: "\(x), \(y), \(z)",
                    form: ChartForm.large
                )
                
                Text("Pitch")
                Text("Method 1: \(String(format: "%.2lf°", vm.ewmaPitch))")
                Text("Method 2: \(String(format: "%.2lf°", vm.comPitch))")
                
                Button(vm.recording ? "Stop recording" : "Start recording") {
                    vm.recording ? vm.stopRecording() : vm.startRecording()
                }
                .frame(alignment: .center)
                .padding(15)
                .background(vm.recording ? Color.red : Color.green)
                .foregroundColor(.white)
                .cornerRadius(8)
                .fileExporter(
                    isPresented: $vm.showingExporter,
                    document: vm.csvFile,
                    contentType: .commaSeparatedText,
                    defaultFilename: "movesense.csv"
                ){ result in
                    switch result {
                    case .success(let url):
                        print("Saved to \(url)")
                    case .failure(let error):
                        print(error.localizedDescription)
                    }
                    
                    vm.showingExporter = false
                }
                
            }
        }
    }
}
