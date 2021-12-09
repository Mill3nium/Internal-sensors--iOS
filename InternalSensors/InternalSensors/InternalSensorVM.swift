import Foundation
import CoreMotion



class InternalSensorVM : ObservableObject {
    
    @Published var ayDegree:String = "-"
    @Published var comPitchka:String = "-"
    
    // n-1 values
    var accelFilteredValue: [Double] = [Double](repeating: 0, count: 3) // index: 0 = x, 1 = y, 2 = x
    var comPitch: [Double] = [Double](repeating: 0, count: 1)
    
    //needed to calculate dt
    var t1:Date = Date.now
    var t2:Date = Date.now
    
    var motionManager = CMMotionManager()
    
    func startGyrometerAndAccelometer(){
        print("Gyrometer & Accelometer")
        
        motionManager.startAccelerometerUpdates(to: OperationQueue.current!){ (data,error) in
            print("Accelometer updates")
            if let accelData = self.motionManager.accelerometerData{
                print("Accelometer data")
  
                self.motionManager.startGyroUpdates(to: OperationQueue.current!){ (data,error) in
                    if let gyroData = self.motionManager.gyroData{
                        
                        let aX = accelData.acceleration.x
                        let aY = accelData.acceleration.y
                        let aZ = accelData.acceleration.z
                        
                        let gY = gyroData.rotationRate.y
                        
                        //accPitch calculation - Work out the squares
                        let aY2 = aY * aY
                        let aZ2 = aZ * aY
                        
                        // Angle X-axis
                        var accPitchTemp = sqrt(aY2 + aZ2)
                        accPitchTemp = (aX / accPitchTemp)
                        accPitchTemp = atan(accPitchTemp) * (180 / Double.pi)
                        
                        var accPitch:Double = 0
                        if !accPitchTemp.isNaN && !accPitchTemp.isInfinite{
                            accPitch = accPitchTemp
                        }
                        
                        // Complementary filter
                        let alpha = 0.1
                        
                        // TODO: Add dT
                        self.comPitch[0] = (1 - alpha) * (self.comPitch[0] + gY) + (alpha * accPitch)
                        print("comPitch: ",self.comPitch[0])
                        
                        self.t2 = Date.now
                        self.comPitchka = String(self.comPitch[0])
                    }
                }
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
                
                // EWMA filter
                let aFilteringFactor = 0.1
                
                self.accelFilteredValue[0] = aFilteringFactor * self.accelFilteredValue[0]  + (1.0 - aFilteringFactor) * accelData.acceleration.x
                self.accelFilteredValue[1] = aFilteringFactor * self.accelFilteredValue[1]  + (1.0 - aFilteringFactor) * accelData.acceleration.y
                self.accelFilteredValue[2] = aFilteringFactor * self.accelFilteredValue[2]  + (1.0 - aFilteringFactor) * accelData.acceleration.z
                
                //angle calculation
                let x_val:Double = self.accelFilteredValue[0]
                let y_val:Double = self.accelFilteredValue[1]
                let z_val:Double = self.accelFilteredValue[2]
                
                // Work out the squares
                let x2:Double = x_val * x_val
                let z2:Double = z_val * z_val
                
                // Angle Y-axis
                var resY = sqrt(x2 + z2)
                resY = y_val / resY
                self.ayDegree = String(atan(resY) * (180 / Double.pi))
            }
        }
    }
}
