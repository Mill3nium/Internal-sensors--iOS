import SwiftUI


struct ButtonView:View {
    @EnvironmentObject var vm : InternalSensorVM
    
    var body : some View{
        Button(action: {
            if vm.isMeasuring {
                vm.stopGyrosAndAccelometer()
            }else{
                vm.startGyrometerAndAccelometer()
            }
        }, label: {
            Text(vm.isMeasuring ? "Stop" : "Start")
                .frame(width: 100, height: 50, alignment: .center)
                .background(vm.isMeasuring ? Color.red : Color.green)
                .foregroundColor(.white)
                .cornerRadius(8)
        }).padding(100)
    }
}
