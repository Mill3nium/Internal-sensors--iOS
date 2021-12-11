import Foundation

struct MeasurementModel:Codable,Identifiable{
    var id = UUID()
    
    var angleComPitch:Double
    var angleAccPitch:Double
    var time:Date
}
