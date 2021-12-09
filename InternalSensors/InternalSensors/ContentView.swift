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
                Text("ComPitch : \(vm.comPitchka)")
            }
            Form{
                Text("Acceleration")
                    .font(.headline)
                    .padding()
                Text("X: \(vm.accelX)")
                Text("Y: \(vm.accelY)")
                Text("Z: \(vm.accelZ)")
                
                Text("Angle (x): \(vm.axDegree)")
                Text("Angle (y): \(vm.ayDegree)")

            }
        }.task {
            vm.startGyrometerAndAccelometer()
            vm.startAccelometer()
        }
    }
}


