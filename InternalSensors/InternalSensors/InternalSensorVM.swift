import Foundation
import CoreMotion
import SwiftUICharts

class InternalSensorVM : ObservableObject {
    var motionManager = CMMotionManager()
    
    @Published var interval = 30
    func setFreq() {
        motionManager.accelerometerUpdateInterval = Double(interval)/1000
        motionManager.gyroUpdateInterval = Double(interval)/1000
    }
    
    @Published var last100ax = Array(repeating: Double(0), count: 100)
    @Published var last100ay = Array(repeating: Double(0), count: 100)
    @Published var last100az = Array(repeating: Double(0), count: 100)
    @Published var chartData: [([Double], GradientColor)] = [
        ([], GradientColors.orange),
        ([], GradientColors.green),
        ([], GradientColors.blue),
    ]
    @Published var ewmaPitch = 0.0
    var lastTime: Date?
    @Published var comPitch = 0.0
    var lastComPitch = 0.0
    
    var filteredAccel = [0.0, 0.0, 0.0]
    
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
                    
                    // Get gyro
                    let gx = gyroData.rotationRate.x
                    let gy = gyroData.rotationRate.y
                    let gz = gyroData.rotationRate.z
                    
                    let time = Date.now
                    
                    // Method 1: Calculate EWMA pitch
                    do {
                        let a = 0.2
                        self.filteredAccel = [
                            a * self.filteredAccel[0] + (1-a)*ax,
                            a * self.filteredAccel[1] + (1-a)*ay,
                            a * self.filteredAccel[2] + (1-a)*az,
                        ]
                        let ax = self.filteredAccel[0]
                        let ay = self.filteredAccel[1]
                        let az = self.filteredAccel[2]
                        let ay2 = ay * ay
                        let az2 = az * az
                        self.ewmaPitch = atan(ax / sqrt(ay2 + az2) ) * (180 / Double.pi)
                    }
                    
                    // Method 2
                    do {
                        if let lastTime = self.lastTime {
                            // Calculate acceleration pitch
                            let ay2 = ay * ay
                            let az2 = az * az
                            let accPitch = atan( ax / sqrt(ay2 + az2) ) * (180 / Double.pi)
                            let dt = (time - lastTime)
                            let a = 0.5
                            self.comPitch = (1-a) * (self.lastComPitch + dt*gy) + a*accPitch;
                            self.lastComPitch = self.comPitch
                        }
                    }
                    
                    self.lastTime = time
                    
                    if self.isRecording {
                        self.csvFile.write(time-self.timeRecordingStarted, ax, ay, az, gx, gy, gz, self.ewmaPitch, self.comPitch)
                        
                        if Date.now - self.timeRecordingStarted > 10 {
                            self.stopRecording()
                        }
                    }
                }
            }
        }
    }
    
    func stopMonitor() {
        motionManager.stopAccelerometerUpdates()
        motionManager.stopGyroUpdates()
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
