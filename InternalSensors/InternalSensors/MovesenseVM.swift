
import Foundation
import CoreBluetooth
import SwiftUICharts
import SwiftUI
import UniformTypeIdentifiers
import CSV

class MovesenseVM: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate, ObservableObject
{
    var centralManager: CBCentralManager!
    
    let GATTService = CBUUID(string: "34802252-7185-4d5d-b431-630e7050e8f0")
    let GATTCommand = CBUUID(string: "34800001-7185-4d5d-b431-630e7050e8f0")
    let GATTData = CBUUID(string: "34800002-7185-4d5d-b431-630e7050e8f0")
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .unknown:
            print("central.state is .unknown")
        case .resetting:
            print("central.state is .resetting")
        case .unsupported:
            print("central.state is .unsupported")
        case .unauthorized:
            print("central.state is .unauthorized")
        case .poweredOff:
            print("central.state is .poweredOff")
        case .poweredOn:
            print("central.state is .poweredOn")
            centralManager.scanForPeripherals(withServices: nil)
        @unknown default:
            print("unknown")
        }
    }
    
    class Sensor: Identifiable {
        let manager: MovesenseVM
        let peripheral: CBPeripheral
        
        init(_ peripheral: CBPeripheral, _ manager: MovesenseVM) {
            self.peripheral = peripheral
            self.manager = manager
        }
        
        func connect() {
            peripheral.delegate = manager
            manager.centralManager.connect(peripheral)
            manager.connectedSensor = self
            manager.stopDiscovery()
        }
        
        func disconnect() {
            manager.connectedSensor = nil
        }
    }
    
    @Published var connectedSensor: Sensor?
    @Published var discoveredSensors = Dictionary<String, Sensor>()
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        
        if let name = peripheral.name, name.contains("Movesense") {
            print("Found \(name)")
            if(!discoveredSensors.contains(where: { key, value in key == name })) {
                discoveredSensors[name] = (Sensor(peripheral, self))
            }
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("didConnect")
        peripheral.discoverServices(nil)
        central.scanForPeripherals(withServices: [GATTService], options: nil)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        for service in peripheral.services!{
            print("Service Found")
            peripheral.discoverCharacteristics([GATTData, GATTCommand], for: service)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        print("didDiscoverCharacteristics")
        guard let characteristics = service.characteristics else { return }
        
        
        for characteristic in characteristics {
            //print(characteristic)
            
            if characteristic.uuid == GATTData {
                print("Data")
                peripheral.setNotifyValue(true, for:characteristic)
            }
            
            if characteristic.uuid == GATTCommand {
                print("Command")
                // Possible sample rates are [13 26 52 104 208 416 833]
                // Link to api https://bitbucket.org/suunto/movesense-device-lib/src/master/
                
                // The string 190/Meas/Gyro/52 to ascii
                //let parameter:[UInt8]  = [1, 90, 47, 77, 101, 97, 115, 47, 71, 121, 114, 111, 47, 53, 50]
                
                // The string 199/Meas/Acc/52 to ascii
                //let parameter:[UInt8] = [1, 99, 47, 77, 101, 97, 115, 47, 65, 99, 99, 47, 53, 50]
                
                //  IMU6 = 73 77 85 54
                let parameter:[UInt8] = [1, 99, 47, 77, 101, 97, 115, 47, 73, 77, 85, 54, 47, 53, 50]
                
                //let parameter:[UInt8] = [2, 99]
                
                let data = NSData(bytes: parameter, length: parameter.count);
                
                peripheral.writeValue(data as Data, for: characteristic, type: CBCharacteristicWriteType.withResponse)
                
                print("Command3 \(parameter.count)")
            }
        }
    }
    
    @Published var last100ax = Array(repeating: Double(0), count: 100)
    @Published var last100ay = Array(repeating: Double(0), count: 100)
    @Published var last100az = Array(repeating: Double(0), count: 100)
    @Published var chartData: [([Double], GradientColor)] = [
        ([], GradientColors.orange),
        ([], GradientColors.green),
        ([], GradientColors.blue),
    ]
    var lastTime: UInt32?
    var lastComPitch: Float = 0.0
    @Published var comPitch: Float = 0
    var filteredAccel: [Float] = [0.0, 0.0, 0.0]
    var ewmaPitch: Float = 0
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic,
                    error: Error?) {
        
        if connectedSensor == nil { return }
        
        switch characteristic.uuid {
        case GATTData:
            let data = characteristic.value
            
            var byteArray: [UInt8] = []
            for i in data! {
                let n : UInt8 = i
                byteArray.append(n)
            }
            
            let response = byteArray[0];
            let reference = byteArray[1];
            
            if(response == 2 && reference == 99){
                let array : [UInt8] = [byteArray[2], byteArray[3], byteArray[4], byteArray[5]]
                var time : UInt32 = 0
                let data = NSData(bytes: array, length: 4)
                data.getBytes(&time, length: 4)
                
                let ax = bytesToFloat(bytes: [byteArray[9], byteArray[8], byteArray[7], byteArray[6]])
                let ay = bytesToFloat(bytes: [byteArray[13], byteArray[12], byteArray[11], byteArray[10]])
                let az = bytesToFloat(bytes: [byteArray[17], byteArray[16], byteArray[15], byteArray[14]])
                last100ax.remove(at: 0); last100ax.append(Double(ax));
                last100ay.remove(at: 0); last100ay.append(Double(ay));
                last100az.remove(at: 0); last100az.append(Double(az));
                chartData = [
                    (last100ax, GradientColors.orange),
                    (last100ay, GradientColors.green),
                    (last100az, GradientColors.blue),
                ]
                
                let gx = bytesToFloat(bytes: [byteArray[21], byteArray[20], byteArray[19], byteArray[18]])
                let gy = bytesToFloat(bytes: [byteArray[25], byteArray[24], byteArray[23], byteArray[22]])
                let gz = bytesToFloat(bytes: [byteArray[29], byteArray[28], byteArray[27], byteArray[26]])
                
                // Method 1: Calculate EWMA pitch
                do {
                    let a: Float = 0.2
                    let ax = a * self.filteredAccel[0] + (1-a)*ax
                    let ay = a * self.filteredAccel[1] + (1-a)*ay
                    let az = a * self.filteredAccel[2] + (1-a)*az
                    self.filteredAccel = [ax, ay, az]
                    let ay2 = ay * ay
                    let az2 = az * az
                    self.ewmaPitch = atan(ax / sqrt(ay2 + az2) ) * (180 / Float.pi)
                }
                
                // Method 2
                do {
                    if let lastTime = self.lastTime {
                        // Calculate acceleration pitch
                        let ay2 = ay * ay
                        let az2 = az * az
                        let accPitch = atan( ax / sqrt(ay2 + az2) ) * (180 / Float.pi)
                        let dt = Float(time - lastTime)/1000
                        let a: Float = 0.5
                        self.comPitch = (1-a) * (self.lastComPitch + dt*gy) + a*accPitch;
                        self.lastComPitch = self.comPitch
                    }
                }
                
                lastTime = time
                
                if isRecording {
                    csvFile.write(time, ax, ay, az, gx, gy, gz)
                    if Date.now - self.timeRecordingStarted > 10 {
                        self.stopRecording()
                    }
                }
            }
            
        case GATTCommand:
            print("Status uppdate")
            
        default:
            print("Unhandled Characteristic UUID:")
        }
    }
    
    func bytesToFloat(bytes b: [UInt8]) -> Float {
        let bigEndianValue = b.withUnsafeBufferPointer {
            $0.baseAddress!.withMemoryRebound(to: UInt32.self, capacity: 1) { $0.pointee }
        }
        let bitPattern = UInt32(bigEndian: bigEndianValue)
        
        return Float(bitPattern: bitPattern)
    }
    
    func startDiscovery(){
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    func stopDiscovery(){
        centralManager.stopScan()
        discoveredSensors = [:]
    }
    
    var timeRecordingStarted = Date.now
    @Published var isRecording = false
    func startRecording() {
        csvFile = CSVFile()
        isRecording = true
    }
    
    @Published var showingExporter = false
    func stopRecording() {
        isRecording = false;
        showingExporter = true;
    }
    
    var csvFile = CSVFile()
}
