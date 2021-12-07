import Foundation
import CoreMotion



class InternalSensorVM : ObservableObject {
    @Published var gDegree:String = "-"
    @Published var gyroX:String = "-"
    @Published var gyroY:String = "-"
    @Published var gyroZ:String = "-"
    
    @Published var aDegree:String = "-"
    @Published var accelX:String = "-"
    @Published var accelY:String = "-"
    @Published var accelZ:String = "-"
    
    // n-1 values
    var accel: [Double] = [Double](repeating: 0, count: 3)
    var gyro: [Double] = [Double](repeating: 0, count: 3)
        
    var motionManager = CMMotionManager()
    
    func startGyrometer(){
        //motionManager.gyroUpdateInterval = 0.5 // how often are we looking for changes
        motionManager.startGyroUpdates(to: OperationQueue.current!){ (data,error) in
            if let gyroData = data {
                //self.gyroX = "\(gyroData.rotationRate.x * (180 / Double.pi))"
                //self.gyroY = "\(gyroData.rotationRate.y * (180 / Double.pi))"
                //self.gyroZ = "\(gyroData.rotationRate.z * (180 / Double.pi))"
                
                // TODO: filer values
                
                let kFilteringFactor = 0.75
                
                self.gyro[0] = kFilteringFactor * self.gyro[0]  + (1.0 - kFilteringFactor) * gyroData.rotationRate.x
                self.gyro[1] = kFilteringFactor * self.gyro[1]  + (1.0 - kFilteringFactor) * gyroData.rotationRate.y
                self.gyro[2] = kFilteringFactor * self.gyro[2]  + (1.0 - kFilteringFactor) * gyroData.rotationRate.z
                
                self.gyroX = String(self.gyro[0] * (180 / Double.pi))
                self.gyroY = String(self.gyro[1] * (180 / Double.pi))
                self.gyroZ = String(self.gyro[2] * (180 / Double.pi))
                
            }
        }
    }
    
    func startAccelometer(){
        //motionManager.accelerometerUpdateInterval = 0.5 // how often are we looking for changes
        motionManager.startAccelerometerUpdates(to: OperationQueue.current!){ (data,error) in
            if let accelData = data {
                //self.accelX = "\(accelData.acceleration.x * 9.8)"
                //self.accelY = "\(accelData.acceleration.y * 9.8)"
                //self.accelZ = "\(accelData.acceleration.z * 9.8)"
                
                // TODO: filer values
                // https://stackoverflow.com/questions/1638864/filtering-accelerometer-data-noise
                
                let kFilteringFactor = 0.2
         
                self.accel[0] = kFilteringFactor * self.accel[0]  + (1.0 - kFilteringFactor) * accelData.acceleration.x
                self.accel[1] = kFilteringFactor * self.accel[1]  + (1.0 - kFilteringFactor) * accelData.acceleration.y
                self.accel[2] = kFilteringFactor * self.accel[2]  + (1.0 - kFilteringFactor) * accelData.acceleration.z

                
                self.accelX = String(9.8 * self.accel[0])
                self.accelY = String(9.8 * self.accel[1])
                self.accelZ = String(9.8 * self.accel[2])

            }
        }
    }
}
