import SwiftUI

struct MeasureView: View {
    @EnvironmentObject var vm : InternalSensorVM
    
    var body: some View {
        VStack{
        Section{
            Form{
                Text("GyroScope & Accelometer")
                    .font(.headline)
                    .padding()
                Text("ComPitch : \(vm.comPitchPlot)")
                
                Text("Accelometer")
                    .font(.headline)
                    .padding()
                Text("AccPitch: \(vm.axDegree)")
            }
        }
            ButtonView()
        }
    }
}


