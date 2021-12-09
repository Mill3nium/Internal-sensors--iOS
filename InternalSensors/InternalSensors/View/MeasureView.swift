import SwiftUI

struct MeasureView: View {
    @EnvironmentObject var vm : InternalSensorVM
    
    var body: some View {
        Section{
            Form{
                Text("GyroScope & Accelometer")
                    .font(.headline)
                    .padding()
                Text("ComPitch : \(vm.comPitchPlot)")
                
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


