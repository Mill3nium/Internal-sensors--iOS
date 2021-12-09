import SwiftUI

struct ContentView: View {
    @EnvironmentObject var vm : InternalSensorVM
    
    var body: some View {
        Section{
            Form{
                Text("GyroScope & Accelometer")
                    .font(.headline)
                    .padding()
                Text("ComPitch : \(vm.comPitchka)")
            }
            Form{
                Text("Accelometer")
                    .font(.headline)
                    .padding()

                Text("Angle (y): \(vm.ayDegree)")
            }
        }.task {
            vm.startGyrometerAndAccelometer()
            //vm.startAccelometer()
        }
    }
}


