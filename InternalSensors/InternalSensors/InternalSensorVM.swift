import Foundation
import CoreMotion



class InternalSensorVM : ObservableObject {
    
    @Published var axDegree:String = "-"
    @Published var comPitchPlot:String = "-"
    
    var timer:Date = Date.now
    var isMeasuring:Bool = false
    
    // n-1 values
    var accelFilteredValue: [Double] = [Double](repeating: 0, count: 3) // index: 0 = x, 1 = y, 2 = z
    var comPitch:Double = 0
    
    var theMeasurements = [MeasurementModel]()
    var index:Int = 0
    
    var motionManager = CMMotionManager()
    var fm:FileManager = FileManager.default

    // TODO: change saving location from phone to computer.
    func saveToFile(){
        //Saving location
        print(fm.urls(for: .documentDirectory, in: .userDomainMask))
    
    }
    
    func stopGyrosAndAccelometer(){
        self.isMeasuring = false
        
        self.motionManager.stopAccelerometerUpdates()
        self.motionManager.stopGyroUpdates()
        
        self.axDegree = "-"
        self.comPitchPlot = "-"
        saveToFile()
    }
    
    func startGyrometerAndAccelometer(){
        //motionManager.accelerometerUpdateInterval = 0.2
        //motionManager.gyroUpdateInterval = 0.2

        motionManager.startAccelerometerUpdates(to: OperationQueue.current!){ (data,error) in
            if let accelData = self.motionManager.accelerometerData{
                
                self.motionManager.startGyroUpdates(to: OperationQueue.current!){ (data,error) in
                    if let gyroData = self.motionManager.gyroData{
                        
                        //timer check
                        if -self.timer.timeIntervalSinceNow > 10{
                            self.isMeasuring = false
                            self.stopGyrosAndAccelometer()
                        } else {
                            self.isMeasuring = true
                        }
                        
                        let aX = accelData.acceleration.x
                        let aY = accelData.acceleration.y
                        let aZ = accelData.acceleration.z
                        
                        let gY = gyroData.rotationRate.y
                        
                        //accPitch calculation - Work out the squares
                        let aY2 = aY * aY
                        let aZ2 = aZ * aZ
                        
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
                        self.comPitch = (1 - alpha) * (self.comPitch + (gY)) + (alpha * accPitch)
                        //print("comPitch: ",self.comPitch[0])
                        
                        self.comPitchPlot = String(format:"%.5f °",self.comPitch)
                        
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
                        self.axDegree = String(format:"%.5f °",atan(resX) * (180 / Double.pi))
                        
                        let measurementsSlowMove = MeasurementModel(
                            angleComPitch: self.comPitch,
                            angleAccPitch: resX,
                            time: Date.now
                        )
                        
                        self.theMeasurements.append(measurementsSlowMove)
                    }
                }
            }
        }
    }
}
