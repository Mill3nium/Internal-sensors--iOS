import SwiftUI

struct ContentView: View {
    @EnvironmentObject var vm : InternalSensorVM
    
    var body: some View {
        Section{
            Form{
                Text("GyroScope & Accelometer")
                    .font(.headline)
                    .padding()
                Text("ComPitch : \(vm.comPitchPlot)")
            }
            Form{
                Text("Accelometer")
                    .font(.headline)
                    .padding()
                Text("Angle (x): \(vm.axDegree)")
            }
        }.task {
            vm.startGyrometerAndAccelometer()
        }
    }
}


