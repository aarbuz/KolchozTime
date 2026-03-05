import SwiftUI

struct AddShiftView: View {
    @ObservedObject var viewModel: AppViewModel
    @Environment(\.presentationMode) var presentationMode
    
    @State private var selectedRole: JobRole = .helper
    @State private var selectedType: ShiftType = .first
    @State private var durationMode: ShiftDuration = .eight
    
    @State private var date: Date
    @State private var startTime = Date()
    @State private var endTime = Date()
    @State private var selectedTask: String = ""
    @State private var customTaskInput: String = ""
    
    init(viewModel: AppViewModel, initialDate: Date = Date()) {
        self.viewModel = viewModel
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
