import SwiftUI
import SwiftUICharts

struct InternalSensorsView: View {
    @EnvironmentObject var vm : InternalSensorVM
    
    var body: some View {
        VStack {
            HStack {
                VStack {
                    Text("Pitch")
                    Text("Method 1: \(String(format: "%.2lf°", vm.ewmaPitch))")
                    Text("Method 2: \(String(format: "%.2lf°", vm.comPitch))")
                }
                
                Spacer()
                
                Button(vm.isRecording ? "Stop recording" : "Start recording") {
                    vm.isRecording ? vm.stopRecording() : vm.startRecording()
                }
                .frame(alignment: .center)
                .padding(15)
                .background(vm.isRecording ? Color.red : Color.green)
                .foregroundColor(.white)
                .cornerRadius(8)
                .fileExporter(
                    isPresented: $vm.showingExporter,
                    document: vm.csvFile,
                    contentType: .commaSeparatedText,
                    defaultFilename: "internalsensor.csv"
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
            .padding(.top, 20)
            .padding(.bottom, 20)
            .padding(.leading, 30)
            .padding(.trailing, 30)
            
            if vm.isRecording {
                Text("Recording for \(String(format: "%.1lf", Date.now - vm.timeRecordingStarted))s")
            }
            
            VStack {
                HStack {
                    Text("Interval:")
                    Picker("Interval", selection: $vm.interval) {
                        ForEach([10, 20, 30, 40, 50, 100, 200, 300], id: \.self) {
                            Text("\($0) ms")
                        }
                    }.onChange(of: vm.interval) { _ in
                        vm.setFreq()
                    }
                }
                
                let x = String(format: "x 🔴: %.2f", vm.last100ax[vm.last100ax.count-1])
                let y = String(format: "y 🟢: %.2f", vm.last100ay[vm.last100ay.count-1])
                let z = String(format: "z 🔵: %.2f", vm.last100az[vm.last100az.count-1])
                MultiLineChartView(
                    data: vm.chartData,
                    title: "Acceleration",
                    legend: "\(x), \(y), \(z)",
                    form: ChartForm.extraLarge
                )
            }
            .padding(.top, 10)
            .padding(.bottom, 30)
            .border(.gray)
        }
        .task {
            vm.startMonitor()
        }
    }
}


