import SwiftUI

struct ContentView: View {
    @EnvironmentObject var vm : InternalSensorVM
    
    var body: some View {
        Section{
            Form{
                Text("GyroScope")
                    .font(.headline)
                    .padding()
                Text(vm.gyroX)
                Text(vm.gyroY)
                Text(vm.gyroZ)
            }
            Form{
                Text("Acceleration")
                    .font(.headline)
                    .padding()
                Text(vm.accelX)
                Text(vm.accelY)
                Text(vm.accelZ)
            }
        }.task {
            vm.getGyroVal()
            vm.getAccelVal()
        }
    }
}


