import SwiftUI
import Combine
import UserNotifications

class AppViewModel: ObservableObject {
    @Published var shifts: [WorkShift] = []
    @Published var helperBaseString: String = "30.00"
    @Published var helperNightString: String = "38.00"
    @Published var operatorBaseString: String = "35.00"
    @Published var operatorNightString: String = "45.00"
    @Published var currentMonthDate = Date()
    @Published var currentQuote: String = ""
    
    @Published var isBackupEnabled: Bool = false {
        didSet {
            UserDefaults.standard.set(isBackupEnabled, forKey: "IsBackupEnabled")
            if isBackupEnabled {
                // ZABEZPIECZENIE: Jeśli włączasz kopię na czystej apce, najpierw próbuje odzyskać dane z pliku
                // żeby nie nadpisać Twojej cennej kopii zapasowej pustą listą!
                if shifts.isEmpty && restoreFromVisibleBackup() {
                    // Odzyskano sukcesem, nic nie robimy
                } else {
                    createVisibleBackup()
                }
            } else {
                deleteVisibleBackup()
            }
        }
    }
    
    let themeColors: [Color] = [
        Color(red: 0.0, green: 0.5, blue: 1.0),
        Color(red: 0.0, green: 0.8, blue: 0.0),
        Color(red: 1.0, green: 0.6, blue: 0.0),
        Color(red: 0.8, green: 0.0, blue: 0.8),
        Color(red: 1.0, green: 0.2, blue: 0.2),
        Color(red: 0.0, green: 0.8, blue: 0.8),
        Color(red: 1.0, green: 0.9, blue: 0.0)
    ]
    
    @Published var accentColor: Color = Color(red: 0.0, green: 0.5, blue: 1.0) {
        didSet { if let hex = accentColor.toHex() { UserDefaults.standard.set(hex, forKey: "AppAccentColor_v2") } }
    }
    
    let quotes = [
        "Jeszcze tylko 30 lat i emerytura.",
        "Kierownik nie śpi, kierownik czuwa.",
        "Szanuj szefa swego, możesz mieć gorszego.",
        "Czy leci z nami BHP?",
        "Robota to głupota, picie to życie.",
        "Kto rano wstaje, ten jest niewyspany.",
        "Tempo, tempo! Taśma nie czeka!",
        "Dzień dobry, czy można już iść do domu?",
        "Co zrobisz jak nic nie zrobisz?",
        "Piątek, piąteczek, piątunio... a nie, zmiana."
    ]
    
    var helperBase: Double { Double(helperBaseString.replacingOccurrences(of: ",", with: ".")) ?? 0.0 }
    var helperNight: Double { Double(helperNightString.replacingOccurrences(of: ",", with: ".")) ?? 0.0 }
    var operatorBase: Double { Double(operatorBaseString.replacingOccurrences(of: ",", with: ".")) ?? 0.0 }
    var operatorNight: Double { Double(operatorNightString.replacingOccurrences(of: ",", with: ".")) ?? 0.0 }
    
    init() {
        loadShifts()
        randomizeQuote()
        requestNotificationPermission()
        if let hex = UserDefaults.standard.string(forKey: "AppAccentColor_v2") { self.accentColor = Color(hex: hex) }
        self.isBackupEnabled = UserDefaults.standard.bool(forKey: "IsBackupEnabled")
    }
    
    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }
    
    func randomizeQuote() { currentQuote = quotes.randomElement() ?? "Do roboty!" }
    
    func changeMonth(by value: Int) {
        if let newDate = Calendar.current.date(byAdding: .month, value: value, to: currentMonthDate) { currentMonthDate = newDate }
    }
    
    func shiftsForCurrentMonth() -> [WorkShift] {
        let calendar = Calendar.current
        return shifts.filter { calendar.isDate($0.date, equalTo: currentMonthDate, toGranularity: .month) }.sorted(by: { $0.date > $1.date })
    }
    
    func getShift(for date: Date) -> WorkShift? {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        return shifts.first { calendar.isDate($0.date, inSameDayAs: startOfDay) }
    }
    
    func currentMonthSalary() -> Double { return shiftsForCurrentMonth().reduce(0) { $0 + $1.earnings } }
    func currentMonthHours() -> Double { return shiftsForCurrentMonth().reduce(0) { $0 + $1.hoursCount } }
    
    func getShiftTypeStats() -> [ShiftType: Double] {
        var currentStats: [ShiftType: Double] = [.first: 0, .second: 0, .third: 0, .custom: 0]
        for shift in shiftsForCurrentMonth() { if let type = ShiftType(rawValue: shift.type) { currentStats[type] = (currentStats[type] ?? 0) + 1 } }
        return currentStats
    }
    
    func getStatsDescription() -> String {
        let stats = getShiftTypeStats()
        return "1. Zmiana: \(Int(stats[.first] ?? 0))\n2. Zmiana: \(Int(stats[.second] ?? 0))\n3. Zmiana / Nocki: \(Int(stats[.third] ?? 0))\nInne: \(Int(stats[.custom] ?? 0))"
    }
    
    func generateReport(includeRoles: Bool) -> String {
        let formatter = DateFormatter(); formatter.dateFormat = "dd.MM.yyyy"
        var report = "GODZINKI \(monthName(from: currentMonthDate).uppercased())\n\n"
        var totalHours = 0.0
        for shift in shiftsForCurrentMonth().sorted(by: { $0.date < $1.date }) {
            totalHours += shift.hoursCount
            let isNight = shift.type.contains("Noc") || shift.type.contains("3.")
            let roleString = includeRoles ? " [\(shift.role)]" : ""
            report += "\(formatter.string(from: shift.date)) | \(String(format: "%g", shift.hoursCount))h | \(shift.taskName)\(roleString)\(isNight ? " (NOCKA)" : "")\n"
        }
        report += "\n----------------\nRAZEM: \(String(format: "%g", totalHours)) GODZIN"
        return report
    }
    
    func generateCSV() -> String {
        var csv = "Data;Zmiana;Zadanie;Rola;Godziny;Zarobki (PLN)\n"
        let f = DateFormatter(); f.dateFormat = "dd.MM.yyyy"
        for shift in shiftsForCurrentMonth().sorted(by: { $0.date < $1.date }) {
            let earningsStr = String(format: "%.2f", shift.earnings).replacingOccurrences(of: ".", with: ",")
            let hoursStr = String(format: "%g", shift.hoursCount).replacingOccurrences(of: ".", with: ",")
            csv += "\(f.string(from: shift.date));\(shift.type);\(shift.taskName);\(shift.role);\(hoursStr);\(earningsStr)\n"
        }
        return csv
    }
    
    func monthName(from date: Date) -> String {
        let f = DateFormatter(); f.locale = Locale(identifier: "pl_PL"); f.dateFormat = "LLLL yyyy"
        return f.string(from: date).capitalized
    }
    
    func addShift(type: ShiftType, is12h: Bool, date: Date, start: Date, end: Date, task: String, role: JobRole) {
        let normalizedDate = Calendar.current.startOfDay(for: date)
        shifts.removeAll { Calendar.current.isDate($0.date, inSameDayAs: normalizedDate) }
        let selectedBaseRate = (role == .operatorMachine) ? operatorBase : helperBase
        let selectedNightRate = (role == .operatorMachine) ? operatorNight : helperNight
        let newShift = WorkShift(date: normalizedDate, type: type.rawValue, startTime: start, endTime: end, baseRate: selectedBaseRate, nightRate: selectedNightRate, taskName: task, role: role.rawValue, isTwelveHours: is12h)
        shifts.append(newShift)
        saveShifts()
        scheduleNotification(for: newShift)
    }
    
    func scheduleNotification(for shift: WorkShift) {
        let triggerDate = shift.endTime.addingTimeInterval(-15 * 60)
        if triggerDate > Date() {
            let content = UNMutableNotificationContent()
            content.title = "Koniec zmiany blisko! 🚨"
            content.body = ["Pora zwijać mandżur!", "Kierownik nie patrzy, można powoli się pakować.", "Jeszcze 15 minut i wolność!", "Taśma nie czeka, ale Ty już możesz."].randomElement()!
            content.sound = .default
            let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: triggerDate)
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            UNUserNotificationCenter.current().add(UNNotificationRequest(identifier: shift.id.uuidString, content: content, trigger: trigger))
        }
    }
    
    func deleteShift(id: UUID) { shifts.removeAll { $0.id == id }; saveShifts() }
    
    func createVisibleBackup() {
        guard isBackupEnabled else { return }
        let docsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileURL = docsURL.appendingPathComponent("KolchozBackup.json")
        if let encoded = try? JSONEncoder().encode(shifts) {
            try? encoded.write(to: fileURL)
        }
    }
    
    func deleteVisibleBackup() {
        let docsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileURL = docsURL.appendingPathComponent("KolchozBackup.json")
        try? FileManager.default.removeItem(at: fileURL)
    }
    
    func restoreFromVisibleBackup() -> Bool {
        let docsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileURL = docsURL.appendingPathComponent("KolchozBackup.json")
        if let data = try? Data(contentsOf: fileURL),
           let decoded = try? JSONDecoder().decode([WorkShift].self, from: data) {
            shifts = decoded
            if let encoded = try? JSONEncoder().encode(shifts) { UserDefaults.standard.set(encoded, forKey: "SavedShifts_v5") }
            return true
        }
        return false
    }
    
    func saveShifts() {
        if let encoded = try? JSONEncoder().encode(shifts) { UserDefaults.standard.set(encoded, forKey: "SavedShifts_v5") }
        UserDefaults.standard.set(helperBaseString, forKey: "HelperBaseStr")
        UserDefaults.standard.set(helperNightString, forKey: "HelperNightStr")
        UserDefaults.standard.set(operatorBaseString, forKey: "OperatorBaseStr")
        UserDefaults.standard.set(operatorNightString, forKey: "OperatorNightStr")
        createVisibleBackup()
    }
    
    func loadShifts() {
        if let data = UserDefaults.standard.data(forKey: "SavedShifts_v5"), let decoded = try? JSONDecoder().decode([WorkShift].self, from: data) { shifts = decoded }
        if let hb = UserDefaults.standard.string(forKey: "HelperBaseStr") { helperBaseString = hb }
        if let hn = UserDefaults.standard.string(forKey: "HelperNightStr") { helperNightString = hn }
        if let ob = UserDefaults.standard.string(forKey: "OperatorBaseStr") { operatorBaseString = ob }
        if let on = UserDefaults.standard.string(forKey: "OperatorNightStr") { operatorNightString = on }
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, opacity: Double(a) / 255)
    }
    func toHex() -> String? {
        let uic = UIColor(self)
        guard let components = uic.cgColor.components, components.count >= 3 else { return nil }
        let r = Float(components[0]), g = Float(components[1]), b = Float(components[2])
        return String(format: "%02lX%02lX%02lX", lroundf(r * 255), lroundf(g * 255), lroundf(b * 255))
    }
}
