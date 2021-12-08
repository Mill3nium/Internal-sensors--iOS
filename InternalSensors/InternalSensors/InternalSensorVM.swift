import Foundation
import CoreMotion



class InternalSensorVM : ObservableObject {
    @Published var gDegree:String = "-"
    @Published var gyroX:String = "-"
    @Published var gyroY:String = "-"
    @Published var gyroZ:String = "-"
    
    @Published var axDegree:String = "-"
    @Published var ayDegree:String = "-"
    
    @Published var accelX:String = "-"
    @Published var accelY:String = "-"
    @Published var accelZ:String = "-"
    
    // n-1 values
    var accelTemp: [Double] = [Double](repeating: 0, count: 3)
    var gyroTemp: [Double] = [Double](repeating: 0, count: 3)
        
    var motionManager = CMMotionManager()
    
    func startGyrometer(){
        //motionManager.gyroUpdateInterval = 0.5 // how often are we looking for changes
        motionManager.startGyroUpdates(to: OperationQueue.current!){ (data,error) in
            if let gyroData = data {
                // TODO: filer values
                
                let gFilteringFactor = 0.1
                
                self.gyroTemp[0] = gFilteringFactor * self.gyroTemp[0]  + (1.0 - gFilteringFactor) * gyroData.rotationRate.x
                self.gyroTemp[1] = gFilteringFactor * self.gyroTemp[1]  + (1.0 - gFilteringFactor) * gyroData.rotationRate.y
                self.gyroTemp[2] = gFilteringFactor * self.gyroTemp[2]  + (1.0 - gFilteringFactor) * gyroData.rotationRate.z
                
                self.gyroX = String(self.gyroTemp[0] * (180 / Double.pi))
                self.gyroY = String(self.gyroTemp[1] * (180 / Double.pi))
                self.gyroZ = String(self.gyroTemp[2] * (180 / Double.pi))
                
                
            }
        }
    }
    
    /// value 1.0 representing an acceleration of 9.8 meters per second in the given direction.
    /// Acceleration values may be positive or negative depending on the direction of the acceleration.
    /// https://www.hobbytronics.co.uk/accelerometer-info
    func startAccelometer(){
        //motionManager.accelerometerUpdateInterval = 0.5 // how often are we looking for changes
        motionManager.startAccelerometerUpdates(to: OperationQueue.current!){ (data,error) in
            if let accelData = data {

                // filter values
                let aFilteringFactor = 0.1
         
                self.accelTemp[0] = aFilteringFactor * self.accelTemp[0]  + (1.0 - aFilteringFactor) * accelData.acceleration.x
                self.accelTemp[1] = aFilteringFactor * self.accelTemp[1]  + (1.0 - aFilteringFactor) * accelData.acceleration.y
                self.accelTemp[2] = aFilteringFactor * self.accelTemp[2]  + (1.0 - aFilteringFactor) * accelData.acceleration.z

                self.accelX = String(9.8 * self.accelTemp[0])
                self.accelY = String(9.8 * self.accelTemp[1])
                self.accelZ = String(9.8 * self.accelTemp[2])
                
                //angle calculation
                let x_val:Double = self.accelTemp[0]
                let y_val:Double = self.accelTemp[1]
                let z_val:Double = self.accelTemp[2]
                
                // Work out the squares
                let x2:Double = x_val * x_val
                let y2:Double = y_val * y_val
                let z2:Double = z_val * z_val
                
                // Angle X-axis
                var resX = sqrt(y2 + z2)
                resX = x_val / resX
                self.axDegree = String(atan(resX) * (180 / Double.pi))
                
                // Angle Y-axis
                var resY = sqrt(x2 + z2)
                resY = y_val / resY
                self.ayDegree = String(atan(resY) * (180 / Double.pi))
            }
        }
    }
}
