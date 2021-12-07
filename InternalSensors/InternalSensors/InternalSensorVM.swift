import Foundation
import CoreMotion



class InternalSensorVM : ObservableObject {
    @Published var gyroX:String = "-"
    @Published var gyroY:String = "-"
    @Published var gyroZ:String = "-"
    
    @Published var accelX:String = "-"
    @Published var accelY:String = "-"
    @Published var accelZ:String = "-"
    
    var motionManager = CMMotionManager()
    
    func getGyroVal(){
       // motionManager.gyroUpdateInterval = 0.5 // how often are we looking for changes
        motionManager.startGyroUpdates(to: OperationQueue.current!){ (data,error) in
            if let gyroData = data {
                self.gyroX = "\(gyroData.rotationRate.x)"
                self.gyroY = "\(gyroData.rotationRate.y)"
                self.gyroZ = "\(gyroData.rotationRate.x)"
            }
        }
    }
    
    func getAccelVal(){
       // motionManager.accelerometerUpdateInterval = 0.5 // how often are we looking for changes
        motionManager.startAccelerometerUpdates(to: OperationQueue.current!){ (data,error) in
            if let accelData = data {
                self.accelX = "\(accelData.acceleration.x)"
                self.accelY = "\(accelData.acceleration.y)"
                self.accelZ = "\(accelData.acceleration.z)"
            }
        }
    }
    
    
}
