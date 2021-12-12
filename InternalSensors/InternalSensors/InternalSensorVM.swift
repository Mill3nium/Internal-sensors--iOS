import Foundation
import CoreMotion
import SwiftUICharts

class InternalSensorVM : ObservableObject {
    var motionManager = CMMotionManager()
    
    @Published var selectedFrequency = 30.0
    func setFreq() {
        motionManager.accelerometerUpdateInterval = selectedFrequency/1000
        motionManager.gyroUpdateInterval = selectedFrequency/1000
        print(selectedFrequency)
    }
    
    @Published var last100ax = Array(repeating: Double(0), count: 100)
    @Published var last100ay = Array(repeating: Double(0), count: 100)
    @Published var last100az = Array(repeating: Double(0), count: 100)
    @Published var chartData: [([Double], GradientColor)] = [
        ([], GradientColors.orange),
        ([], GradientColors.green),
        ([], GradientColors.blue),
    ]
    @Published var accPitch = 0.0
    var lastTime: Date?
    @Published var comPitch = 0.0
    var lastComPitch = 0.0
    
    func stopMonitor() {
        motionManager.stopAccelerometerUpdates()
        motionManager.stopGyroUpdates()
    }
    
    func startMonitor() {
        setFreq()
        
        motionManager.startAccelerometerUpdates(to: OperationQueue.current!){ (data,error) in
            
        }
        
        self.motionManager.startGyroUpdates(to: OperationQueue.current!){ (data,error) in
            if let gyroData = self.motionManager.gyroData {
                if let accelData = self.motionManager.accelerometerData {
                    // Get acceleration
                    let ax = accelData.acceleration.x
                    let ay = accelData.acceleration.y
                    let az = accelData.acceleration.z
                    self.last100ax.remove(at: 0); self.last100ax.append(Double(ax));
                    self.last100ay.remove(at: 0); self.last100ay.append(Double(ay));
                    self.last100az.remove(at: 0); self.last100az.append(Double(az));
                    self.chartData = [
                        (self.last100ax, GradientColors.orange),
                        (self.last100ay, GradientColors.green),
                        (self.last100az, GradientColors.blue),
                    ]
                    
                    // Calculate acceleration pitch
                    let ay2 = ay * ay
                    let az2 = az * az
                    self.accPitch = atan( ax / sqrt(ay2 + az2) ) * (180 / Double.pi)
                    
                    // Get gyroscope
                    let gx = gyroData.rotationRate.x
                    let gy = gyroData.rotationRate.y
                    let gz = gyroData.rotationRate.z
                    
                    let time = Date.now
                    if let lastTime = self.lastTime {
                        let dt = (time - lastTime)
                        let a = 0.5
                        self.comPitch = (1-a) * (self.lastComPitch + dt*gy) + a*self.accPitch;
                        self.lastComPitch = self.comPitch
                    }
                    
                    self.lastTime = time
                    
                    if self.isRecording {
                        self.csvFile.write(time, ax, ay, az, gx, gy, gz)
                        
                        if Date.now - self.timeRecordingStarted > 10 {
                            self.stopRecording()
                        }
                    }
                    
                    // EWMA filter
    //                        let aFilteringFactor = 0.1
    //
    //                        self.accelFilteredValue[0] = aFilteringFactor * self.accelFilteredValue[0]  + (1.0 - aFilteringFactor) * accelData.acceleration.x
    //                        self.accelFilteredValue[1] = aFilteringFactor * self.accelFilteredValue[1]  + (1.0 - aFilteringFactor) * accelData.acceleration.y
    //                        self.accelFilteredValue[2] = aFilteringFactor * self.accelFilteredValue[2]  + (1.0 - aFilteringFactor) * accelData.acceleration.z
    //
    //                        //angle calculation
    //                        let x_val:Double = self.accelFilteredValue[0]
    //                        let y_val:Double = self.accelFilteredValue[1]
    //                        let z_val:Double = self.accelFilteredValue[2]
    //
    //                        // Work out the squares
    //                        let y2:Double = y_val * y_val
    //                        let z2:Double = z_val * z_val
    //
    //                        // Angle X-axis
    //                        var resX = sqrt(y2 + z2)
    //                        resX = x_val / resX
    //                        self.axDegree = String(format:"%.5f °",atan(resX) * (180 / Double.pi))
                }
            }
        }
    }
    
    var timeRecordingStarted = Date.now
    @Published var isRecording = false
    func startRecording() {
        csvFile = CSVFile()
        timeRecordingStarted = Date.now
        isRecording = true
    }
    
    @Published var showingExporter = false
    func stopRecording() {
        isRecording = false;
        showingExporter = true;
    }
    
    var csvFile = CSVFile()
}

extension Date {
    static func - (lhs: Date, rhs: Date) -> TimeInterval {
        return lhs.timeIntervalSinceReferenceDate - rhs.timeIntervalSinceReferenceDate
    }
}
