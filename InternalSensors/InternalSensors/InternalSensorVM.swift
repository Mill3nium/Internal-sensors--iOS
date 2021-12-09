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
    
    @Published var comPitchka:String = "-"
    
    // n-1 values
    var accelFilteredValue: [Double] = [Double](repeating: 0, count: 3) // index: 0 = x, 1 = y, 2 = x
    var comPitch: [Double] = [Double](repeating: 0, count: 1)
    
    var motionManager = CMMotionManager()
    
    func startGyrometerAndAccelometer(){
        motionManager.startGyroUpdates()
        motionManager.startAccelerometerUpdates()
                
        guard let accelData = self.motionManager.accelerometerData else { return }
        guard let gyroData = self.motionManager.gyroData else { return }
        
        let aX = accelData.acceleration.x
        let aY = accelData.acceleration.y
        let aZ = accelData.acceleration.z
        
        let gY = gyroData.rotationRate.y
        
        //accPitch calculation - Work out the squares
        let aX2 = aX * aX
        let aY2 = aY * aY
        let aZ2 = aZ * aY
        
        // Angle X-axis
        var accPitch = sqrt(aY2 + aZ2)
        accPitch = aX2 / accPitch
        
        // Complementary filter
        let alpha = 0.1
        
        self.comPitch[0] = (1 - alpha) * (self.comPitch[0] + gY) + (alpha * accPitch)
        self.comPitchka = String(self.comPitch[0])
    }
    
    /// value 1.0 representing an acceleration of 9.8 meters per second in the given direction.
    /// Acceleration values may be positive or negative depending on the direction of the acceleration.
    /// https://www.hobbytronics.co.uk/accelerometer-info
    func startAccelometer(){
        //motionManager.accelerometerUpdateInterval = 0.5 // how often are we looking for changes
        motionManager.startAccelerometerUpdates(to: OperationQueue.current!){ (data,error) in
            if let accelData = data {
                
                // EWMA filter
                let aFilteringFactor = 0.1
                
                self.accelFilteredValue[0] = aFilteringFactor * self.accelFilteredValue[0]  + (1.0 - aFilteringFactor) * accelData.acceleration.x
                self.accelFilteredValue[1] = aFilteringFactor * self.accelFilteredValue[1]  + (1.0 - aFilteringFactor) * accelData.acceleration.y
                self.accelFilteredValue[2] = aFilteringFactor * self.accelFilteredValue[2]  + (1.0 - aFilteringFactor) * accelData.acceleration.z
                
                self.accelX = String(9.8 * self.accelFilteredValue[0])
                self.accelY = String(9.8 * self.accelFilteredValue[1])
                self.accelZ = String(9.8 * self.accelFilteredValue[2])
                
                //angle calculation
                let x_val:Double = self.accelFilteredValue[0]
                let y_val:Double = self.accelFilteredValue[1]
                let z_val:Double = self.accelFilteredValue[2]
                
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
