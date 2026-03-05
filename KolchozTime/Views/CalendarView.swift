import SwiftUI

struct SelectedDate: Identifiable {
    let id = UUID()
    let date: Date
}

struct CalendarGridView: View {
    @ObservedObject var viewModel: AppViewModel
    @State private var selectedShift: WorkShift?
    @State private var selectedDateForNewShift: SelectedDate?
    
    let columns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)
    let daysOfWeek = ["Pn", "Wt", "Śr", "Cz", "Pt", "Sb", "Nd"]
    
    var body: some View {
        ScrollView {
            VStack {
                LazyVGrid(columns: columns) { ForEach(daysOfWeek, id: \.self) { day in Text(day).font(.caption).bold().foregroundColor(.gray).frame(maxWidth: .infinity).padding(.vertical, 5) } }
                
                LazyVGrid(columns: columns, spacing: 0) {
                    ForEach(daysInMonth(), id: \.self) { date in
                        if let date = date {
                            let shift = viewModel.getShift(for: date)
                            let isToday = Calendar.current.isDateInToday(date)
                            
                            VStack(spacing: 3) {
                                Text("\(Calendar.current.component(.day, from: date))")
                                    .font(.system(size: 16, weight: isToday ? .black : .bold, design: .rounded))
                                    .foregroundColor(isToday ? .white : (shift != nil ? .white : .gray))
                                
                                if let shift = shift {
                                    Circle()
                                        .fill(shift.type.contains("3.") || shift.type.contains("Noc") ? .blue : (shift.type.contains("2.") ? .purple : .orange))
                                        .frame(width: 8, height: 8)
                                        // Czarna obwódka kropki, by odcinała się od tła
                                        .overlay(Circle().stroke(Color.black, lineWidth: 1.5))
                                } else {
                                    Circle().fill(Color.clear).frame(width: 8, height: 8)
                                }
                            }
                            .frame(maxWidth: .infinity).frame(height: 60)
                            .background(
                                ZStack {
                                    if isToday {
                                        // Tło dzisiejszego dnia dopasowane ciemniejszym gradientem
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(LinearGradient(gradient: Gradient(colors: [viewModel.accentColor.opacity(0.5), viewModel.accentColor.opacity(0.2)]), startPoint: .topLeading, endPoint: .bottomTrailing))
                                            .padding(2)
                                    } else if shift != nil {
                                        RoundedRectangle(cornerRadius: 8).fill(Color.white.opacity(0.1)).padding(2)
                                    }
                                    RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.2), lineWidth: 0.5).padding(1)
                                }
                            )
                            .contentShape(Rectangle())
                            .onTapGesture {
                                if let s = shift { selectedShift = s }
                                else { selectedDateForNewShift = SelectedDate(date: date) }
                            }
                            
                        } else {
                            Color.clear.frame(height: 60)
                        }
                    }
                }
                Color.clear.frame(height: 150)
            }.padding(.horizontal, 10)
        }
        .sheet(item: $selectedShift) { shift in ShiftDetailView(shift: shift, viewModel: viewModel) }
        .sheet(item: $selectedDateForNewShift) { sd in AddShiftView(viewModel: viewModel, initialDate: sd.date) }
    }
    
    func daysInMonth() -> [Date?] {
        let calendar = Calendar.current
        let interval = calendar.dateInterval(of: .month, for: viewModel.currentMonthDate)!
        let firstDay = interval.start
        let firstWeekday = calendar.component(.weekday, from: firstDay)
        let offset = (firstWeekday + 5) % 7
        var days: [Date?] = Array(repeating: nil, count: offset)
        let range = calendar.range(of: .day, in: .month, for: viewModel.currentMonthDate)!
        for day in range {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: firstDay) { days.append(date) }
        }
        return days
    }
}
