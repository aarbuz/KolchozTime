import SwiftUI

struct ContentView: View {
    @StateObject var viewModel = AppViewModel()
    @State private var showingAddShift = false
    @State private var showingSettings = false
    @State private var viewMode = 1
    @State private var showingStatsAlert = false
    @State private var showingReportChoice = false
    @State private var showingShareSheet = false
    @State private var generatedReportText = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)
                VStack(spacing: 0) {
                    VStack(spacing: 2) {
                        Text("CZAS PRACY").font(.system(size: 14, weight: .bold, design: .monospaced)).tracking(2).foregroundColor(.gray).padding(.top, 5)
                        HStack {
                            Button(action: { viewModel.changeMonth(by: -1) }) { Image(systemName: "chevron.left").font(.title2).bold().foregroundColor(.white) }.padding()
                            Spacer(); Text(viewModel.monthName(from: viewModel.currentMonthDate).uppercased()).font(.title3).fontWeight(.black).foregroundColor(.white); Spacer()
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
                            Button(action: { showingReportChoice = true }) { Image(systemName: "doc.text.fill").font(.headline).foregroundColor(.white) }
                            .actionSheet(isPresented: $showingReportChoice) {
                                ActionSheet(title: Text("Raport"), buttons: [.default(Text("Pełny")) { generatedReportText = viewModel.generateReport(includeRoles: true); showingShareSheet = true }, .default(Text("Prosty")) { generatedReportText = viewModel.generateReport(includeRoles: false); showingShareSheet = true }, .cancel()])
                            }
                            .sheet(isPresented: $showingShareSheet) { ShareSheet(activityItems: [generatedReportText]) }
                            Spacer()
                            Picker("Widok", selection: $viewMode) { Image(systemName: "list.bullet").tag(0); Image(systemName: "calendar").tag(1) }.pickerStyle(SegmentedPickerStyle()).frame(width: 100)
                        }
                    }
                    .padding(15)
                    .background(LinearGradient(gradient: Gradient(colors: [viewModel.accentColor, viewModel.accentColor.opacity(0.6)]), startPoint: .topLeading, endPoint: .bottomTrailing))
                    .cornerRadius(20).padding(.horizontal).padding(.bottom, 10)
                    
                    if viewMode == 0 {
                        List {
                            ForEach(viewModel.shiftsForCurrentMonth()) { shift in ShiftRow(shift: shift) }
                            Color.clear.frame(height: 160).listRowBackground(Color.clear)
                        }.listStyle(PlainListStyle()).scrollContentBackground(.hidden)
                    } else {
                        CalendarGridView(viewModel: viewModel)
                    }
                    
                    Text(viewModel.currentQuote).font(.caption).italic().multilineTextAlignment(.center).foregroundColor(.gray).padding(.bottom, 120).padding(.horizontal).onTapGesture { viewModel.randomizeQuote() }
                }
            }
            .navigationBarHidden(true)
            .overlay(
                HStack(spacing: 20) {
                    Button(action: { showingSettings = true }) { Image(systemName: "gearshape.fill").font(.title2).foregroundColor(.white).padding(15).background(Color.white.opacity(0.1)).clipShape(Circle()) }
                    Button(action: { showingAddShift = true }) { Image(systemName: "plus").font(.title).bold().foregroundColor(.white).padding(.horizontal, 40).padding(.vertical, 15).background(viewModel.accentColor).clipShape(Capsule()) }
                }.padding(.bottom, 30), alignment: .bottom
            )
            .sheet(isPresented: $showingAddShift) { AddShiftView(viewModel: viewModel, initialDate: Date()) }
            .sheet(isPresented: $showingSettings) { SettingsView(viewModel: viewModel) }
        }
        .preferredColorScheme(.dark)
    }
}
