import SwiftUI

enum ShiftDuration: String, CaseIterable {
    case eight = "8h"
    case twelve = "12h"
}

enum JobRole: String, CaseIterable, Codable {
    case operatorMachine = "Operator"
    case helper = "Pomocnik"
}

enum ShiftType: String, CaseIterable, Identifiable {
    case first = "1. Zmiana / Dzień"
    case second = "2. Zmiana"
    case third = "3. Zmiana / Noc"
    case custom = "Inna"
    
    var id: String { self.rawValue }
    
    var color: Color {
        switch self {
        case .first: return .orange
        case .second: return .purple
        case .third: return .blue
        case .custom: return .gray
        }
    }
}

struct WorkShift: Identifiable, Codable {
    var id = UUID()
    var date: Date
    var type: String
    var startTime: Date
    var endTime: Date
    
    var baseRate: Double
    var nightRate: Double
    
    var taskName: String
    var role: String
    var isTwelveHours: Bool
    
    var hoursCount: Double {
        let duration = endTime.timeIntervalSince(startTime)
        let totalHours = duration / 3600
        return totalHours < 0 ? totalHours + 24 : totalHours
    }
    
    var earnings: Double {
        let realTotal = hoursCount
        if isTwelveHours && (type == ShiftType.third.rawValue) {
            let dayPart = 4.0 * baseRate
            let nightPart = 8.0 * nightRate
            return dayPart + nightPart
        }
        if !isTwelveHours && (type == ShiftType.third.rawValue) {
            return realTotal * nightRate
        }
        return realTotal * baseRate
    }
}
