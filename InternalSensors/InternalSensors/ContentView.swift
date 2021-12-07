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
        }.task {
            vm.getGyroVal()
            vm.getAccelVal()
        }
        
        Section{
            Form{
                Text("Acceleration")
                    .font(.headline)
                    .padding()
                Text(vm.accelX)
                Text(vm.accelY)
                Text(vm.accelZ)
            }
        }

        
        
    }
}


