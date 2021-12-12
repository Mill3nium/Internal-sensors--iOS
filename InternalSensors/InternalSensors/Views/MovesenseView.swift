import SwiftUI
import SwiftUICharts

struct MovesenseView: View {
    @StateObject var vm = MovesenseVM()
    
    var body: some View {
        VStack {
            if vm.connectedPeripheral == nil {
                Text("Select sensor to connect")
                List(Array(vm.discoveredPeripherals.keys), id: \.self) { key in
                    Button(key) {
                        vm.connect(vm.discoveredPeripherals[key]!)
                    }
                }
                .task {
                    vm.startDiscovery()
                }
            } else {
                Text("\(vm.connectionEstablished ? "Connected" : "Connecting") to \(vm.connectedPeripheral!.name!)")
                
                HStack {
                    Button("Disconnect") {
                        vm.disconnect()
                    }
                    .frame(alignment: .center)
                    .padding(10)
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                    
                    if vm.connectionEstablished {
                        Button(vm.paused ? "Unpause" : "Pause") {
                            vm.paused ? vm.unpause() : vm.pause()
                        }
                        .frame(alignment: .center)
                        .padding(10)
                        .background(vm.paused ? Color.red : Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                    
                }
                
                if vm.connectionEstablished {
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
                    .padding(.top, 20)
                    .padding(.bottom, 20)
                    .padding(.leading, 30)
                    .padding(.trailing, 30)
                    
                    if vm.isRecording {
                        Text("Recording for \(String(format: "%.1lf", Date.now - vm.timeRecordingStarted))s")
                    }
                    
                    VStack {
                        HStack {
                            HStack {
                                Text("Rate:")
                                Picker("Rate", selection: $vm.sampleRate) {
                                    ForEach([13, 26, 52, 104, 208, 416, 833], id: \.self) {
                                        Text("\($0) Hz")
                                    }
                                }
                                .onChange(of: vm.sampleRate) { _ in
                                    vm.applySampleRate()
                                }
                                .disabled(vm.isRecording)
                            }
                            Spacer()
                            HStack {
                                Text("Sensor:")
                                Picker("Sensor", selection: $vm.selectedSensor) {
                                    Text("Accelerometer").tag(0)
                                    Text("Gyroscope").tag(1)
                                    Text("IMU6").tag(2)
                                }
                                .disabled(vm.isRecording)
                            }
                        }
                        .padding(.leading, 30)
                        .padding(.trailing, 30)
                        
                        let gx = String(format: "x: %.2f", vm.gx)
                        let gy = String(format: "y: %.2f", vm.gy)
                        let gz = String(format: "z: %.2f", vm.gz)
                        Text("Gyro: \(gx), \(gy), \(gz)")
                        
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

                
            }
        }
    }
}
