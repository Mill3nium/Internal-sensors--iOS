import Foundation
import CoreMotion



class InternalSensorVM : ObservableObject {
    
    @Published var ayDegree:String = "-"
    @Published var axDegree:String = "-"
    @Published var comPitchPlot:String = "-"
    
    // n-1 values
    var accelFilteredValue: [Double] = [Double](repeating: 0, count: 3) // index: 0 = x, 1 = y, 2 = x
    var comPitch: [Double] = [Double](repeating: 0, count: 1)
    
    //needed to calculate dt?
    var t1:Date = Date.now
    var t2:Date = Date.now
    
    var motionManager = CMMotionManager()
    
    func startGyrometerAndAccelometer(){
        
        //motionManager.accelerometerUpdateInterval = 0.2
        //motionManager.gyroUpdateInterval = 0.2
        
        motionManager.startAccelerometerUpdates(to: OperationQueue.current!){ (data,error) in
            if let accelData = self.motionManager.accelerometerData{
                
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
                        //print("comPitch: ",self.comPitch[0])
                        
                        self.comPitchPlot = String(self.comPitch[0])
                        
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
                        let y2:Double = y_val * y_val
                        let z2:Double = z_val * z_val
                        
                        // Angle X-axis
                        var resX = sqrt(y2 + z2)
                        resX = x_val / resX
                        self.axDegree = String(atan(resX) * (180 / Double.pi))
                    }
                }
            }
        }
    }
}
