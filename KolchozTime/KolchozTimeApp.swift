import SwiftUI
import Combine

// --- MODELE DANYCH ---

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

// --- VIEW MODEL ---

class AppViewModel: ObservableObject {
    @Published var shifts: [WorkShift] = []
    @Published var helperBaseString: String = "30.00"
    @Published var helperNightString: String = "38.00"
    @Published var operatorBaseString: String = "35.00"
    @Published var operatorNightString: String = "45.00"
    @Published var currentMonthDate = Date()
    @Published var currentQuote: String = ""
    
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
    }
    
    func randomizeQuote() { currentQuote = quotes.randomElement() ?? "Do roboty!" }
    
    func changeMonth(by value: Int) {
        if let newDate = Calendar.current.date(byAdding: .month, value: value, to: currentMonthDate) {
            currentMonthDate = newDate
        }
    }
    
    func shiftsForCurrentMonth() -> [WorkShift] {
        let calendar = Calendar.current
        return shifts.filter {
            calendar.isDate($0.date, equalTo: currentMonthDate, toGranularity: .month)
        }.sorted(by: { $0.date > $1.date })
    }
    
    func getShift(for date: Date) -> WorkShift? {
        let calendar = Calendar.current
        return shifts.first { calendar.isDate($0.date, inSameDayAs: date) }
    }
    
    func currentMonthSalary() -> Double {
        return shiftsForCurrentMonth().reduce(0) { $0 + $1.earnings }
    }
    
    func currentMonthHours() -> Double {
        return shiftsForCurrentMonth().reduce(0) { $0 + $1.hoursCount }
    }
    
    func getShiftTypeStats() -> [ShiftType: Double] {
        let shifts = shiftsForCurrentMonth()
        var stats: [ShiftType: Double] = [.first: 0, .second: 0, .third: 0, .custom: 0]
        for shift in shifts {
            if let type = ShiftType(rawValue: shift.type) {
                stats[type] = (stats[type] ?? 0) + 1
            }
        }
        return stats
    }
    
    func getStatsDescription() -> String {
        let stats = getShiftTypeStats()
        return """
        1. Zmiana: \(Int(stats[.first] ?? 0))
        2. Zmiana: \(Int(stats[.second] ?? 0))
        3. Zmiana / Nocki: \(Int(stats[.third] ?? 0))
        Inne: \(Int(stats[.custom] ?? 0))
        """
    }
    
    func generateReport() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy"
        var report = "GODZINKI \(monthName(from: currentMonthDate).uppercased())\n\n"
        var totalHours = 0.0
        for shift in shiftsForCurrentMonth().reversed() {
            totalHours += shift.hoursCount
            let isNight = shift.type.contains("Noc") || shift.type.contains("3.")
            let nightString = isNight ? " (NOCKA)" : ""
            let roleString = " [\(shift.role)]"
            let hString = String(format: "%g", shift.hoursCount)
            report += "\(formatter.string(from: shift.date)) | \(hString)h | \(shift.taskName)\(roleString)\(nightString)\n"
        }
        report += "\n----------------\nRAZEM: \(String(format: "%g", totalHours)) GODZIN"
        return report
    }
    
    func monthName(from date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "pl_PL")
        f.dateFormat = "LLLL yyyy"
        return f.string(from: date).capitalized
    }
    
    func addShift(type: ShiftType, is12h: Bool, date: Date, start: Date, end: Date, task: String, role: JobRole) {
        shifts.removeAll { Calendar.current.isDate($0.date, inSameDayAs: date) }
        let selectedBaseRate = (role == .operatorMachine) ? operatorBase : helperBase
        let selectedNightRate = (role == .operatorMachine) ? operatorNight : helperNight
        let newShift = WorkShift(
            date: date, type: type.rawValue, startTime: start, endTime: end,
            baseRate: selectedBaseRate, nightRate: selectedNightRate,
            taskName: task, role: role.rawValue, isTwelveHours: is12h
        )
        shifts.append(newShift)
        saveShifts()
    }
    
    func deleteShift(at offsets: IndexSet) {
        let shiftsToDelete = offsets.map { shiftsForCurrentMonth()[$0] }
        shifts.removeAll { shift in shiftsToDelete.contains(where: { $0.id == shift.id }) }
        saveShifts()
    }
    func deleteShift(id: UUID) {
        shifts.removeAll { $0.id == id }
        saveShifts()
    }
    
    func saveShifts() {
        if let encoded = try? JSONEncoder().encode(shifts) { UserDefaults.standard.set(encoded, forKey: "SavedShifts_v5") }
        UserDefaults.standard.set(helperBaseString, forKey: "HelperBaseStr")
        UserDefaults.standard.set(helperNightString, forKey: "HelperNightStr")
        UserDefaults.standard.set(operatorBaseString, forKey: "OperatorBaseStr")
        UserDefaults.standard.set(operatorNightString, forKey: "OperatorNightStr")
    }
    
    func loadShifts() {
        if let data = UserDefaults.standard.data(forKey: "SavedShifts_v5"),
           let decoded = try? JSONDecoder().decode([WorkShift].self, from: data) { shifts = decoded }
        if let hb = UserDefaults.standard.string(forKey: "HelperBaseStr") { helperBaseString = hb }
        if let hn = UserDefaults.standard.string(forKey: "HelperNightStr") { helperNightString = hn }
        if let ob = UserDefaults.standard.string(forKey: "OperatorBaseStr") { operatorBaseString = ob }
        if let on = UserDefaults.standard.string(forKey: "OperatorNightStr") { operatorNightString = on }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    var activityItems: [Any]
    var applicationActivities: [UIActivity]? = nil
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
        return controller
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// --- GŁÓWNY WIDOK ---

struct ContentView: View {
    @StateObject var viewModel = AppViewModel()
    @State private var showingAddShift = false
    @State private var showingSettings = false
    @State private var viewMode = 1
    @State private var showingStatsAlert = false
    @State private var showingShareSheet = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 0) {
                    VStack(spacing: 2) {
                        Text("CZAS PRACY")
                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                            .tracking(2).foregroundColor(.gray).padding(.top, 5)
                        HStack {
                            Button(action: { viewModel.changeMonth(by: -1) }) { Image(systemName: "chevron.left").font(.title2).bold().foregroundColor(.white) }.padding()
                            Spacer()
                            Text(viewModel.monthName(from: viewModel.currentMonthDate).uppercased()).font(.title3).fontWeight(.black).foregroundColor(.white)
                            Spacer()
                            Button(action: { viewModel.changeMonth(by: 1) }) { Image(systemName: "chevron.right").font(.title2).bold().foregroundColor(.white) }.padding()
                        }
                    }.padding(.bottom, 5)
                    
                    VStack(spacing: 12) {
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Do wypłaty").font(.caption).bold().foregroundColor(.white.opacity(0.7)).textCase(.uppercase)
                                Text("\(viewModel.currentMonthSalary(), specifier: "%.2f") zł").font(.system(size: 34, weight: .bold, design: .rounded)).foregroundColor(.white)
                            }
                            Spacer()
                            Button(action: { showingStatsAlert = true }) {
                                DonutChart(stats: viewModel.getShiftTypeStats(), total: Double(viewModel.shiftsForCurrentMonth().count))
                                    .frame(width: 45, height: 45)
                                    .overlay(Image(systemName: "info.circle").font(.caption2).foregroundColor(.white.opacity(0.5)).offset(x: 18, y: -18))
                            }
                            .alert(isPresented: $showingStatsAlert) { Alert(title: Text("Statystyki Zmian"), message: Text(viewModel.getStatsDescription()), dismissButton: .default(Text("OK"))) }
                        }
                        Divider().background(Color.white.opacity(0.3))
                        HStack {
                            Label { Text("\(String(format: "%g", viewModel.currentMonthHours())) h").font(.system(size: 16, weight: .bold, design: .rounded)) } icon: { Image(systemName: "clock.fill").foregroundColor(.white.opacity(0.8)) }.foregroundColor(.white)
                            Spacer()
                            Button(action: { showingShareSheet = true }) { Image(systemName: "doc.text.fill").font(.headline).foregroundColor(.blue) }
                            .sheet(isPresented: $showingShareSheet) { ShareSheet(activityItems: [viewModel.generateReport()]) }
                            Spacer()
                            Picker("Widok", selection: $viewMode) { Image(systemName: "list.bullet").tag(0); Image(systemName: "calendar").tag(1) }.pickerStyle(SegmentedPickerStyle()).frame(width: 100)
                        }
                    }
                    .padding(15)
                    .background(LinearGradient(gradient: Gradient(colors: [Color(red: 0.1, green: 0.3, blue: 0.2), Color(red: 0.05, green: 0.1, blue: 0.05)]), startPoint: .topLeading, endPoint: .bottomTrailing))
                    .cornerRadius(20).shadow(color: Color.green.opacity(0.2), radius: 8, x: 0, y: 4).padding(.horizontal).padding(.bottom, 10)
                    
                    if viewMode == 0 {
                        List {
                            ForEach(viewModel.shiftsForCurrentMonth()) { shift in ShiftRow(shift: shift) }.onDelete(perform: viewModel.deleteShift)
                            Color.clear.frame(height: 150).listRowBackground(Color.clear)
                        }.listStyle(PlainListStyle()).scrollContentBackground(.hidden)
                    } else {
                        // Tutaj przekazujemy logikę kalendarza
                        CalendarGridView(viewModel: viewModel)
                    }
                    
                    VStack {
                        Divider().background(Color.gray.opacity(0.3))
                        Text(viewModel.currentQuote).font(.caption).italic().multilineTextAlignment(.center).foregroundColor(.gray).padding(.top, 8).padding(.horizontal)
                    }.padding(.bottom, 20).onTapGesture { viewModel.randomizeQuote() }
                }
            }
            .navigationBarHidden(true)
            .overlay(
                VStack {
                    HStack {
                        Button(action: { showingSettings = true }) { Image(systemName: "gearshape.fill").font(.title2).foregroundColor(.gray).padding(12).background(Color.black.opacity(0.8)).clipShape(Circle()) }
                        Spacer()
                        Button(action: { showingAddShift = true }) { Image(systemName: "plus").font(.title2).bold().foregroundColor(.white).padding(15).background(Color.blue).clipShape(Circle()).shadow(color: .blue.opacity(0.4), radius: 8, x: 0, y: 4) }
                    }.padding(.horizontal, 20)
                }.padding(.bottom, 50), alignment: .bottom
            )
            .sheet(isPresented: $showingAddShift) {
                // Domyślne dodawanie (dzisiaj)
                AddShiftView(viewModel: viewModel, initialDate: Date())
            }
            .sheet(isPresented: $showingSettings) { SettingsView(viewModel: viewModel) }
        }
        .preferredColorScheme(.dark)
    }
}

// --- WYKRES KOŁOWY ---
struct DonutChart: View {
    let stats: [ShiftType: Double]; let total: Double
    var body: some View {
        ZStack {
            if total == 0 { Circle().stroke(Color.gray.opacity(0.3), lineWidth: 6); Text("0%").font(.system(size: 10, weight: .bold)).foregroundColor(.white.opacity(0.5)) }
            else {
                Circle().stroke(Color.gray.opacity(0.3), lineWidth: 6)
                ForEach(ShiftType.allCases) { type in if let value = stats[type], value > 0 { Circle().trim(from: startTrim(for: type), to: endTrim(for: type)).stroke(type.color, lineWidth: 6).rotationEffect(.degrees(-90)) } }
                Text("STAT").font(.system(size: 10, weight: .bold)).foregroundColor(.white)
            }
        }
    }
    func startTrim(for type: ShiftType) -> CGFloat { var start: CGFloat = 0.0; for t in ShiftType.allCases { if t == type { break }; start += CGFloat((stats[t] ?? 0) / total) }; return start }
    func endTrim(for type: ShiftType) -> CGFloat { return startTrim(for: type) + CGFloat((stats[type] ?? 0) / total) }
}

struct ShiftRow: View {
    let shift: WorkShift
    var shiftColor: Color { if shift.type.contains("1.") || shift.type.contains("Dzień") { return .orange }; if shift.type.contains("2.") { return .purple }; return .blue }
    var body: some View {
        HStack {
            ZStack { Circle().fill(shiftColor.opacity(0.2)).frame(width: 40, height: 40); Image(systemName: shiftColor == .blue ? "moon.fill" : (shiftColor == .purple ? "sunset.fill" : "sun.max.fill")).foregroundColor(shiftColor) }
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(shift.taskName).font(.headline).foregroundColor(.white)
                    Text("(\(shift.role))").font(.caption2).foregroundColor(.gray).textCase(.uppercase)
                }
                HStack { Text(shift.date, style: .date); Text("•"); Text(shift.isTwelveHours ? "12h" : "8h").bold().foregroundColor(.yellow) }.font(.caption).foregroundColor(.gray)
            }
            Spacer()
            Text("+\(shift.earnings, specifier: "%.2f") zł").bold().foregroundColor(.green)
        }.listRowBackground(Color.white.opacity(0.05))
    }
}

// --- KALENDARZ (Z LOGIKĄ KLIKANIA W PUSTY DZIEŃ) ---
struct CalendarGridView: View {
    @ObservedObject var viewModel: AppViewModel
    @State private var selectedShift: WorkShift?
    
    // Nowe stany do dodawania z kalendarza
    @State private var showingAddFromCalendar = false
    @State private var dateForNewShift = Date()
    
    let columns = Array(repeating: GridItem(.flexible(), spacing: 5), count: 7)
    let daysOfWeek = ["Pn", "Wt", "Śr", "Cz", "Pt", "Sb", "Nd"]
    
    var body: some View {
        ScrollView {
            VStack {
                LazyVGrid(columns: columns) { ForEach(daysOfWeek, id: \.self) { day in Text(day).font(.caption).bold().foregroundColor(.gray) } }
                LazyVGrid(columns: columns, spacing: 5) {
                    ForEach(daysInMonth(), id: \.self) { date in
                        if let date = date {
                            let shift = viewModel.getShift(for: date)
                            let isToday = Calendar.current.isDateInToday(date)
                            VStack {
                                Text("\(Calendar.current.component(.day, from: date))").font(.system(size: 14, weight: isToday ? .black : .bold, design: .rounded)).foregroundColor(isToday ? .blue : (shift != nil ? .white : .gray))
                                if let shift = shift { Circle().fill(shift.type.contains("3.") || shift.type.contains("Noc") ? .blue : (shift.type.contains("2.") ? .purple : .orange)).frame(width: 8, height: 8) }
                                else { Circle().fill(Color.clear).frame(width: 8, height: 8) }
                            }
                            .frame(maxWidth: .infinity, minHeight: 50)
                            .background(RoundedRectangle(cornerRadius: 8).fill(shift != nil ? Color.white.opacity(0.1) : Color.clear))
                            .overlay(isToday ? RoundedRectangle(cornerRadius: 8).stroke(Color.blue.opacity(0.5), lineWidth: 1) : nil)
                            .onTapGesture {
                                if let s = shift {
                                    // Kliknięto w zmianę -> Pokaż detale
                                    selectedShift = s
                                } else {
                                    // Kliknięto w pusty dzień -> Dodaj zmianę
                                    dateForNewShift = date
                                    showingAddFromCalendar = true
                                }
                            }
                        } else { Text("") }
                    }
                }
                Color.clear.frame(height: 150)
            }.padding()
        }
        .sheet(item: $selectedShift) { shift in ShiftDetailView(shift: shift, viewModel: viewModel) }
        .sheet(isPresented: $showingAddFromCalendar) {
            AddShiftView(viewModel: viewModel, initialDate: dateForNewShift)
        }
    }
    func daysInMonth() -> [Date?] {
        let calendar = Calendar.current
        let interval = calendar.dateInterval(of: .month, for: viewModel.currentMonthDate)!
        let firstDay = interval.start; let firstWeekday = calendar.component(.weekday, from: firstDay); let offset = (firstWeekday + 5) % 7
        var days: [Date?] = Array(repeating: nil, count: offset)
        let range = calendar.range(of: .day, in: .month, for: viewModel.currentMonthDate)!
        for day in range { if let date = calendar.date(byAdding: .day, value: day - 1, to: firstDay) { days.append(date) } }
        return days
    }
}

struct ShiftDetailView: View {
    let shift: WorkShift
    @ObservedObject var viewModel: AppViewModel
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            VStack(spacing: 25) {
                Capsule().fill(Color.gray).frame(width: 40, height: 5).padding(.top)
                Text(shift.taskName.uppercased()).font(.system(size: 28, weight: .black)).foregroundColor(.white)
                Text(shift.role.uppercased()).font(.caption).bold().padding(6).background(Color.white.opacity(0.2)).cornerRadius(5).foregroundColor(.white)
                HStack(spacing: 15) {
                    DetailBox(icon: "clock.fill", title: shift.isTwelveHours ? "12h" : "8h", color: .blue)
                    DetailBox(icon: "banknote.fill", title: String(format: "%.2f zł", shift.earnings), color: .green)
                    DetailBox(icon: "calendar", title: formatDate(shift.date), color: .orange)
                }
                Divider().background(Color.gray)
                HStack { Text("Dokładne godziny:").foregroundColor(.gray); Spacer(); Text("\(shift.startTime, style: .time) - \(shift.endTime, style: .time)").bold().foregroundColor(.white) }.padding(.horizontal)
                Spacer()
                Button(action: { viewModel.deleteShift(id: shift.id); presentationMode.wrappedValue.dismiss() }) { Text("Usuń tę zmianę").bold().frame(maxWidth: .infinity).padding().background(Color.red.opacity(0.2)).foregroundColor(.red).cornerRadius(15) }.padding(.horizontal).padding(.bottom)
            }.padding()
        }
    }
    func formatDate(_ date: Date) -> String { let f = DateFormatter(); f.dateFormat = "dd.MM"; return f.string(from: date) }
}

struct DetailBox: View {
    let icon: String; let title: String; let color: Color
    var body: some View { VStack { Image(systemName: icon).font(.title2).foregroundColor(color).padding(.bottom, 5); Text(title).font(.headline).foregroundColor(.white) }.frame(maxWidth: .infinity).padding().background(Color.white.opacity(0.1)).cornerRadius(15) }
}

// --- DODAWANIE (Z INICJALIZACJĄ DATY) ---
struct AddShiftView: View {
    @ObservedObject var viewModel: AppViewModel
    @Environment(\.presentationMode) var presentationMode
    
    @State private var selectedRole: JobRole = .helper
    @State private var selectedType: ShiftType = .first
    @State private var durationMode: ShiftDuration = .eight
    
    // Zmienione na var, inicjalizowane w init
    @State private var date: Date
    
    @State private var startTime = Date()
    @State private var endTime = Date()
    @State private var selectedTask: String = ""
    @State private var customTaskInput: String = ""
    
    // Konstruktor przyjmujący datę
    init(viewModel: AppViewModel, initialDate: Date = Date()) {
        self.viewModel = viewModel
        // Inicjalizacja stanu daty
        _date = State(initialValue: initialDate)
    }
    
    let operatorTasks = ["B4", "Przepakówka", "B3", "B4 puste", "P1", "P2", "Inne"]
    let helperTasks = ["Przepakowka", "Wylewanie", "Linia", "Przebieranie", "Strefa", "Prace techniczne", "Robot", "Inne"]
    
    var currentTasks: [String] { selectedRole == .operatorMachine ? operatorTasks : helperTasks }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Stanowisko")) {
                    Picker("Rola", selection: $selectedRole) {
                        ForEach(JobRole.allCases, id: \.self) { role in Text(role.rawValue).tag(role) }
                    }.pickerStyle(SegmentedPickerStyle())
                    .onChange(of: selectedRole) { _ in selectedTask = ""; customTaskInput = "" }
                }
                Section(header: Text("Kiedy i ile?")) {
                    DatePicker("Data", selection: $date, displayedComponents: .date)
                        .onChange(of: date) { _ in calculateTimes() }
                    Picker("Długość zmiany", selection: $durationMode) {
                        ForEach(ShiftDuration.allCases, id: \.self) { item in Text(item.rawValue).tag(item) }
                    }.pickerStyle(SegmentedPickerStyle())
                    .onChange(of: durationMode) { _ in calculateTimes() }
                }
                Section(header: Text("Zmiana")) {
                    Picker("Rodzaj", selection: $selectedType) {
                        if durationMode == .eight {
                            Text("1. Zmiana (6-14)").tag(ShiftType.first)
                            Text("2. Zmiana (14-22)").tag(ShiftType.second)
                            Text("3. Zmiana (22-6)").tag(ShiftType.third)
                        } else {
                            Text("Dzień (6-18)").tag(ShiftType.first)
                            Text("Noc (18-6)").tag(ShiftType.third)
                        }
                        Text("Inna (Ręczna)").tag(ShiftType.custom)
                    }.pickerStyle(MenuPickerStyle())
                    .onChange(of: selectedType) { _ in calculateTimes() }
                    
                    if selectedType == .custom {
                        DatePicker("Start", selection: $startTime, displayedComponents: .hourAndMinute)
                        DatePicker("Koniec", selection: $endTime, displayedComponents: .hourAndMinute)
                    }
                }
                Section(header: Text("Zadanie")) {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 10) {
                        ForEach(currentTasks, id: \.self) { task in
                            Button(action: { selectedTask = task }) {
                                Text(task).font(.caption).fontWeight(.bold).padding(.vertical, 8)
                                    .frame(maxWidth: .infinity)
                                    .background(selectedTask == task ? Color.blue : Color.gray.opacity(0.3))
                                    .foregroundColor(.white).cornerRadius(8)
                            }.buttonStyle(PlainButtonStyle())
                        }
                    }.padding(.vertical, 5)
                    if selectedTask == "Inne" { TextField("Wpisz co robiłeś...", text: $customTaskInput) }
                }
                Button(action: {
                    let finalTaskName = (selectedTask == "Inne") ? (customTaskInput.isEmpty ? "Inne" : customTaskInput) : selectedTask
                    let safeTaskName = finalTaskName.isEmpty ? currentTasks.first! : finalTaskName
                    viewModel.addShift(type: selectedType, is12h: durationMode == .twelve, date: date, start: startTime, end: endTime, task: safeTaskName, role: selectedRole)
                    presentationMode.wrappedValue.dismiss()
                }) { HStack { Spacer(); Text("ZAPISZ").bold(); Spacer() } }.listRowBackground(Color.green).foregroundColor(.white)
            }
            .navigationTitle("Dodaj Zmianę").onAppear {
                calculateTimes()
                if selectedTask.isEmpty { selectedTask = currentTasks.first ?? "" }
            }
        }
    }
    func calculateTimes() {
        let c = Calendar.current
        var comp = c.dateComponents([.year, .month, .day], from: date)
        if selectedType == .custom { return }
        if durationMode == .eight {
            switch selectedType {
            case .first: comp.hour=6; startTime=c.date(from:comp)!; comp.hour=14; endTime=c.date(from:comp)!
            case .second: comp.hour=14; startTime=c.date(from:comp)!; comp.hour=22; endTime=c.date(from:comp)!
            case .third: comp.hour=22; startTime=c.date(from:comp)!; comp.hour=6; comp.day!+=1; endTime=c.date(from:comp)!
            default: break
            }
        } else {
            switch selectedType {
            case .first, .second: comp.hour=6; startTime=c.date(from:comp)!; comp.hour=18; endTime=c.date(from:comp)!
            case .third: comp.hour=18; startTime=c.date(from:comp)!; comp.hour=6; comp.day!+=1; endTime=c.date(from:comp)!
            default: break
            }
        }
    }
}

struct SettingsView: View {
    @ObservedObject var viewModel: AppViewModel
    @Environment(\.presentationMode) var presentationMode
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Stawki - POMOCNIK")) {
                    HStack { Text("Podstawowa").bold(); Spacer(); TextField("0.00", text: $viewModel.helperBaseString).keyboardType(.decimalPad).multilineTextAlignment(.trailing) }
                    HStack { Text("Nocna").bold(); Spacer(); TextField("0.00", text: $viewModel.helperNightString).keyboardType(.decimalPad).multilineTextAlignment(.trailing) }
                }
                Section(header: Text("Stawki - OPERATOR")) {
                    HStack { Text("Podstawowa").bold().foregroundColor(.blue); Spacer(); TextField("0.00", text: $viewModel.operatorBaseString).keyboardType(.decimalPad).multilineTextAlignment(.trailing) }
                    HStack { Text("Nocna").bold().foregroundColor(.blue); Spacer(); TextField("0.00", text: $viewModel.operatorNightString).keyboardType(.decimalPad).multilineTextAlignment(.trailing) }
                }
                Button(action: { presentationMode.wrappedValue.dismiss() }) { HStack { Spacer(); Text("Zapisz Ustawienia").bold(); Spacer() } }.foregroundColor(.green)
            }.navigationTitle("Ustawienia")
        }
    }
}

@main
struct KolchozTimeApp: App {
    var body: some Scene { WindowGroup { ContentView() } }
}
