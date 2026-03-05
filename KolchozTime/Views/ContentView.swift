import SwiftUI

struct OnboardingView: View {
    @ObservedObject var viewModel: AppViewModel
    @Binding var hasSeenOnboarding: Bool
    
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            VStack(spacing: 25) {
                Spacer()
                Image(systemName: "clock.badge.checkmark.fill").font(.system(size: 80)).foregroundColor(viewModel.accentColor)
                Text("Witaj w pracy!").font(.largeTitle).bold().foregroundColor(.white)
                Text("Zanim zaczniesz liczyć wypłatę, ustaw swoje domyślne stawki. Będziesz mógł je w każdej chwili zmienić w ustawieniach.").foregroundColor(.gray).multilineTextAlignment(.center).padding(.horizontal)
                
                VStack(spacing: 15) {
                    HStack { Text("Pomocnik - Dzień").foregroundColor(.white); Spacer(); TextField("0.00", text: $viewModel.helperBaseString).keyboardType(.decimalPad).multilineTextAlignment(.trailing).foregroundColor(.white).frame(width: 80) }
                    HStack { Text("Pomocnik - Noc").foregroundColor(.white); Spacer(); TextField("0.00", text: $viewModel.helperNightString).keyboardType(.decimalPad).multilineTextAlignment(.trailing).foregroundColor(.white).frame(width: 80) }
                    Divider().background(Color.gray.opacity(0.5))
                    HStack { Text("Operator - Dzień").foregroundColor(.white); Spacer(); TextField("0.00", text: $viewModel.operatorBaseString).keyboardType(.decimalPad).multilineTextAlignment(.trailing).foregroundColor(.white).frame(width: 80) }
                    HStack { Text("Operator - Noc").foregroundColor(.white); Spacer(); TextField("0.00", text: $viewModel.operatorNightString).keyboardType(.decimalPad).multilineTextAlignment(.trailing).foregroundColor(.white).frame(width: 80) }
                }
                .padding(20)
                .background(Color.white.opacity(0.1))
                .cornerRadius(15)
                .padding(.horizontal)
                
                Spacer()
                
                Button(action: {
                    viewModel.saveShifts()
                    hasSeenOnboarding = true
                }) {
                    Text("ZACZYNAMY").font(.headline).bold().foregroundColor(.white).frame(maxWidth: .infinity).padding().background(viewModel.accentColor).cornerRadius(15)
                }.padding(.horizontal).padding(.bottom, 30)
            }
        }
        .preferredColorScheme(.dark)
    }
}

struct ContentView: View {
    @StateObject var viewModel = AppViewModel()
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    
    @State private var showingAddShift = false
    @State private var showingSettings = false
    @State private var viewMode = 1 // Zmiana z 0 na 1 (Domyślnie Kalendarz)
    @State private var showingStatsAlert = false
    @State private var showingReportChoice = false
    @State private var showingShareSheet = false
    @State private var generatedReportText = ""
    
    var body: some View {
        if !hasSeenOnboarding {
            OnboardingView(viewModel: viewModel, hasSeenOnboarding: $hasSeenOnboarding)
        } else {
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
                                    ActionSheet(title: Text("Wybierz Format Raportu"), buttons: [
                                        .default(Text("Zwykły Tekst (do wysłania)")) { generatedReportText = viewModel.generateReport(includeRoles: true); showingShareSheet = true },
                                        .default(Text("Arkusz Kalkulacyjny Excel (CSV)")) { generatedReportText = viewModel.generateCSV(); showingShareSheet = true },
                                        .cancel()
                                    ])
                                }
                                .sheet(isPresented: $showingShareSheet) { ShareSheet(activityItems: [generatedReportText]) }
                                Spacer()
                                Picker("Widok", selection: $viewMode) { Image(systemName: "list.bullet").tag(0); Image(systemName: "calendar").tag(1) }.pickerStyle(SegmentedPickerStyle()).frame(width: 100)
                            }
                        }
                        .padding(15)
                        .background(LinearGradient(gradient: Gradient(colors: [viewModel.accentColor.opacity(0.4), Color.black.opacity(0.8)]), startPoint: .topLeading, endPoint: .bottomTrailing))
                        .cornerRadius(20).padding(.horizontal).padding(.bottom, 10)
                        
                        ZStack(alignment: .bottom) {
                            Group {
                                if viewMode == 0 {
                                    ScrollView {
                                        VStack(spacing: 12) {
                                            ForEach(viewModel.shiftsForCurrentMonth()) { shift in
                                                ShiftRow(shift: shift, viewModel: viewModel)
                                            }
                                            Color.clear.frame(height: 150)
                                        }
                                        .padding(.horizontal)
                                        .padding(.top, 5)
                                    }
                                } else {
                                    CalendarGridView(viewModel: viewModel)
                                }
                            }
                            
                            VStack(spacing: 0) {
                                LinearGradient(gradient: Gradient(colors: [.clear, .black]), startPoint: .top, endPoint: .bottom)
                                    .frame(height: 40)
                                    .allowsHitTesting(false)
                                
                                Text(viewModel.currentQuote)
                                    .font(.caption)
                                    .italic()
                                    .multilineTextAlignment(.center)
                                    .foregroundColor(.gray)
                                    .frame(maxWidth: .infinity)
                                    .padding(.horizontal, 15)
                                    .padding(.top, 5)
                                    .padding(.bottom, 90)
                                    .background(Color.black)
                                    .onTapGesture { viewModel.randomizeQuote() }
                            }
                        }
                    }
                }
                .navigationBarHidden(true)
                .overlay(
                    HStack(spacing: 20) {
                        Button(action: { showingSettings = true }) { Image(systemName: "gearshape.fill").font(.title2).foregroundColor(.white).padding(15).background(Color.white.opacity(0.15)).clipShape(Circle()) }
                        Button(action: { showingAddShift = true }) {
                            Image(systemName: "plus").font(.title).bold().foregroundColor(.white).padding(.horizontal, 40).padding(.vertical, 15)
                                .background(LinearGradient(gradient: Gradient(colors: [viewModel.accentColor.opacity(0.6), viewModel.accentColor.opacity(0.3)]), startPoint: .topLeading, endPoint: .bottomTrailing))
                                .clipShape(Capsule())
                        }
                    }.padding(.bottom, 15), alignment: .bottom
                )
                .sheet(isPresented: $showingAddShift) { AddShiftView(viewModel: viewModel, initialDate: Date()) }
                .sheet(isPresented: $showingSettings) { SettingsView(viewModel: viewModel) }
            }
            .preferredColorScheme(.dark)
        }
    }
}
