
import Foundation
import CoreBluetooth
import SwiftUICharts
import SwiftUI
import UniformTypeIdentifiers
import CSV

class MovesenseVM: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate, ObservableObject
{
    @Published var selectedSensor = 2
    @Published var sampleRate = 13
    func applySampleRate() {
        pause()
        unpause()
    }
    
    @Published var paused = false
    func pause() {
        paused = true
        let parameter:[UInt8] = [2, 99]
        let data = NSData(bytes: parameter, length: parameter.count)
        connectedPeripheral!.writeValue(data as Data, for: characteristics[GATTCommand]!, type: CBCharacteristicWriteType.withResponse)
    }
    func unpause() {
        paused = false
        let parameter = [1, 99] + [UInt8]("/Meas/IMU6/\(sampleRate)".data(using: String.Encoding.ascii)!)
        let data  = NSData(bytes: parameter, length: parameter.count)
        connectedPeripheral!.writeValue(data as Data, for: characteristics[GATTCommand]!, type: CBCharacteristicWriteType.withResponse)
    }
    
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
    
    @Published var discoveredPeripherals: [String:CBPeripheral] = [:]
    @Published var connectedPeripheral: CBPeripheral?
    func connect(_ peripheral: CBPeripheral) {
        peripheral.delegate = self
        centralManager.connect(peripheral)
        connectedPeripheral = peripheral
        stopDiscovery()
    }
    
    func disconnect() {
        centralManager.cancelPeripheralConnection(connectedPeripheral!)
        connectedPeripheral = nil
        connectionEstablished = false
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        
        if let name = peripheral.name, name.contains("Movesense") {
            print("Found \(name)")
            if(!discoveredPeripherals.contains(where: { key, value in key == name })) {
                discoveredPeripherals[name] = (peripheral)
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
    
    @Published var connectionEstablished = false
    var characteristics: [CBUUID:CBCharacteristic] = [:]
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        print("didDiscoverCharacteristics")
        guard let characteristics = service.characteristics else {return}
        
        for characteristic in characteristics {
            //print(characteristic)
            self.characteristics[characteristic.uuid] = characteristic
            
            if characteristic.uuid == GATTData {
                print("Data")
                peripheral.setNotifyValue(true, for:characteristic)
            }
            
            if characteristic.uuid == GATTCommand {
                connectionEstablished = true
                print("Command")
                // Possible sample rates are [13 26 52 104 208 416 833]
                // Link to api https://bitbucket.org/suunto/movesense-device-lib/src/master/
                
                // /Meas/Gyro/52
                // /Meas/Acc/52
                
                let parameter = [1, 99] + [UInt8]("/Meas/IMU6/\(sampleRate)".data(using: String.Encoding.ascii)!)
                let data  = NSData(bytes: parameter, length: parameter.count)
                peripheral.writeValue(data as Data, for: characteristic, type: CBCharacteristicWriteType.withResponse)
                
                //                print("Command3 \(parameter.count)")
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
    
    @Published var gx: Float = 0
    @Published var gy: Float = 0
    @Published var gz: Float = 0
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic,
                    error: Error?) {
        
        if connectedPeripheral == nil { return }
        
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
                for i in 0...(sampleRate/13)-1 {
                    let stride = i*24
                    if byteArray.count <= stride+6 {
                        print("OVERSIZE")
                        break
                    }
                    
                    var time : UInt32 = 0
                    let data = NSData(bytes: Array(byteArray[stride+2...stride+5]), length: 4)
                    data.getBytes(&time, length: 4)
                    
                    let ax = bytesToFloat(bytes: byteArray[stride+6...stride+9])
                    let ay = bytesToFloat(bytes: byteArray[stride+10...stride+13])
                    let az = bytesToFloat(bytes: byteArray[stride+14...stride+17])
                    if self.selectedSensor != 0 {
                        gx = bytesToFloat(bytes: byteArray[stride+18...stride+21])
                        gy = bytesToFloat(bytes: byteArray[stride+22...stride+25])
                        gz = bytesToFloat(bytes: byteArray[stride+26...stride+29])
                    }
                    
                    if self.selectedSensor != 1 {
                        last100ax.remove(at: 0); last100ax.append(Double(ax));
                        last100ay.remove(at: 0); last100ay.append(Double(ay));
                        last100az.remove(at: 0); last100az.append(Double(az));
                        chartData = [
                            (last100ax, GradientColors.orange),
                            (last100ay, GradientColors.green),
                            (last100az, GradientColors.blue),
                        ]
                    }
                    
                    // Method 1: Calculate EWMA pitch
                    if self.selectedSensor != 1 {
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
                    if self.selectedSensor == 2 {
                        if let lastTime = self.lastTime {
                            do {
                                // Calculate acceleration pitch
                                let ay2 = ay * ay
                                let az2 = az * az
                                let accPitch = atan( ax / sqrt(ay2 + az2) ) * (180 / Float.pi)
                                if lastTime < time {
                                    let dt = Float(time - lastTime)/1000
                                    let a: Float = 0.5
                                    self.comPitch = (1-a) * (self.lastComPitch + dt*gy) + a*accPitch;
                                    self.lastComPitch = self.comPitch
                                } else {
                                    print("TIME OVERFLOW")
                                    self.comPitch = 0
                                    self.lastComPitch = 0
                                }
                            }
                        }
                    }
                    
                    lastTime = time
                    
                    if isRecording {
                        csvFile.write(time, ax, ay, az, gx, gy, gz, ewmaPitch, comPitch)
                        if Date.now - self.timeRecordingStarted > 10 {
                            self.stopRecording()
                        }
                    }
                }
            }
            
        case GATTCommand:
            print("Status uppdate")
            
        default:
            print("Unhandled Characteristic UUID:")
        }
    }
    
    func bytesToFloat(bytes b: ArraySlice<UInt8>) -> Float {
        let bigEndianValue = b.reversed().withUnsafeBufferPointer {
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
        discoveredPeripherals = [:]
    }
    
    var timeRecordingStarted = Date.now
    @Published var isRecording = false
    func startRecording() {
        csvFile = CSVFile()
        isRecording = true
        timeRecordingStarted = Date.now
    }
    
    @Published var showingExporter = false
    func stopRecording() {
        isRecording = false;
        showingExporter = true;
    }
    
    var csvFile = CSVFile()
}
