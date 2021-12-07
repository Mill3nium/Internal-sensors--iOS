import SwiftUI

struct ContentView: View {
    @EnvironmentObject var vm : InternalSensorVM
    
    var body: some View {
        Section{
            Form{
                Text("GyroScope")
                    .font(.headline)
                    .padding()
                Text("X: \(vm.gyroX)")
                Text("Y: \(vm.gyroY)")
                Text("Z: \(vm.gyroZ)")
                Text("Degree : \(vm.gDegree)")
            }
            Form{
                Text("Acceleration")
                    .font(.headline)
                    .padding()
                Text("X: \(vm.accelX)")
                Text("Y: \(vm.accelY)")
                Text("Z: \(vm.accelZ)")
                Text("Degree : \(vm.aDegree)")
            }
        }.task {
            vm.startGyrometer()
            vm.startAccelometer()
        }
    }
}


