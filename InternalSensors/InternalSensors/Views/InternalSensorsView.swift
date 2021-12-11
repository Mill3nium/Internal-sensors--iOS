import SwiftUI

struct InternalSensorsView: View {
    @EnvironmentObject var vm : InternalSensorVM
    
    var body: some View {
        VStack {
            Text("GyroScope & Accelometer")
                .font(.headline)
                .padding()
            Text("ComPitch : \(String(format: "%.2lf°", vm.comPitch))")
            
            Text("Accelometer")
                .font(.headline)
                .padding()
            Text("AccPitch: \(String(format: "%.2lf°", vm.accPitch))")
            
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
            
            if vm.isRecording {
                Text("Recording for \(String(format: "%.1lf", Date.now - vm.timeRecordingStarted))s")
            }
        }
        .task {
            vm.startMonitor()
        }
    }
}


