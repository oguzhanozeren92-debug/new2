import SwiftUI

@main
struct SatrancAkademisiApp: App {
    var body: some Scene {
        WindowGroup {
            AcademyRootView()
                .preferredColorScheme(.dark)
                .tint(Theme.gold)
        }
    }
}

enum Theme {
    static let background = Color(red: 0.035, green: 0.085, blue: 0.14)
    static let surface = Color(red: 0.075, green: 0.16, blue: 0.23)
    static let gold = Color(red: 0.92, green: 0.73, blue: 0.45)
    static let cream = Color(red: 0.98, green: 0.92, blue: 0.81)
}

enum AcademyTab: String, CaseIterable, Identifiable {
    case home = "Ana Sayfa", lessons = "Dersler", puzzles = "Bulmaca", play = "Oyna", profile = "Profil"
    var id: String { rawValue }
    var icon: String {
        switch self {
        case .home: return "house.fill"
        case .lessons: return "books.vertical.fill"
        case .puzzles: return "square.grid.3x3.fill"
        case .play: return "checkerboard.rectangle"
        case .profile: return "person.crop.circle.fill"
        }
    }
}

struct AcademyRootView: View {
    @AppStorage("academy.nickname") private var nickname = ""
    @AppStorage("academy.skill") private var skill = "Yeni başlıyorum"
    @State private var selectedTab: AcademyTab = .home

    var body: some View {
        Group {
            if nickname.isEmpty {
                AcademyOnboarding(nickname: $nickname, skill: $skill)
            } else {
                TabView(selection: $selectedTab) {
                    AcademyHomeView(nickname: nickname) { selectedTab = .lessons }
                        .tabItem { Label(AcademyTab.home.rawValue, systemImage: AcademyTab.home.icon) }
                        .tag(AcademyTab.home)
                    CoursesView()
                        .tabItem { Label(AcademyTab.lessons.rawValue, systemImage: AcademyTab.lessons.icon) }
                        .tag(AcademyTab.lessons)
                    PuzzlesView()
                        .tabItem { Label(AcademyTab.puzzles.rawValue, systemImage: AcademyTab.puzzles.icon) }
                        .tag(AcademyTab.puzzles)
                    BotMenuView()
                        .tabItem { Label(AcademyTab.play.rawValue, systemImage: AcademyTab.play.icon) }
                        .tag(AcademyTab.play)
                    AcademyProfileView(nickname: $nickname, skill: $skill)
                        .tabItem { Label(AcademyTab.profile.rawValue, systemImage: AcademyTab.profile.icon) }
                        .tag(AcademyTab.profile)
                }
            }
        }
        .background(Theme.background.ignoresSafeArea())
    }
}

struct AcademyOnboarding: View {
    @Binding var nickname: String
    @Binding var skill: String
    @State private var input = ""
    @State private var selectedSkill = "Yeni başlıyorum"
    @State private var warning = ""
    private let levels = ["Yeni başlıyorum", "Biraz biliyorum", "İyi biliyorum"]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 22) {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 47))
                        .foregroundStyle(Theme.gold)
                        .accessibilityHidden(true)
                    Text("Satranç yolculuğun başlıyor")
                        .font(.system(.largeTitle, design: .serif, weight: .bold))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(Theme.cream)
                    Text("Derslere başlamak için bir rumuz ve seviyeni seç. E-posta gerekmiyor.")
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)
                    TextField("Rumuzun", text: $input)
                        .textContentType(.nickname)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .padding(14)
                        .background(.black.opacity(0.25), in: RoundedRectangle(cornerRadius: 12))
                        .accessibilityLabel("Oyuncu rumuzu")
                    VStack(spacing: 9) {
                        ForEach(levels, id: \.self) { level in
                            Button {
                                selectedSkill = level
                                warning = ""
                            } label: {
                                HStack {
                                    Text(level)
                                    Spacer()
                                    if selectedSkill == level { Image(systemName: "checkmark.circle.fill") }
                                }
                                .frame(minHeight: 44)
                                .padding(.horizontal, 14)
                            }
                            .buttonStyle(.bordered)
                            .tint(selectedSkill == level ? Theme.gold : .gray)
                            .accessibilityAddTraits(selectedSkill == level ? .isSelected : [])
                        }
                    }
                    Button("Öğrenmeye Başla") { start() }
                        .buttonStyle(.borderedProminent)
                        .tint(Theme.gold)
                        .foregroundStyle(.black)
                        .frame(minHeight: 44)
                    Button("Rumuz oluşturmadan dene") {
                        nickname = "Misafir"
                        skill = selectedSkill
                    }
                    .buttonStyle(.borderless)
                    .frame(minHeight: 44)
                    if !warning.isEmpty {
                        Text(warning).foregroundStyle(.red).accessibilityAddTraits(.updatesFrequently)
                    }
                }
                .padding(22)
                .frame(maxWidth: 540)
                .frame(maxWidth: .infinity)
            }
            .background(Theme.background.ignoresSafeArea())
        }
    }

    private func start() {
        let candidate = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard (3...20).contains(candidate.count) else {
            warning = "Rumuz 3–20 karakter olmalı."
            return
        }
        skill = selectedSkill
        nickname = candidate
    }
}

struct AcademyHomeView: View {
    let nickname: String
    let onLearning: () -> Void
    @AppStorage("academy.completed") private var completed = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("SATranç AKADEMİSİ").font(.caption.weight(.heavy)).tracking(2).foregroundStyle(Theme.gold)
                        Text("Her hamlede daha iyi ol.")
                            .font(.system(.largeTitle, design: .serif, weight: .bold))
                            .foregroundStyle(Theme.cream)
                        Text("Tahtada öğren, hamleni yap, nedenini anla. Merhaba, \(nickname)!")
                            .foregroundStyle(.secondary)
                        Button(action: onLearning) {
                            Label("Eğitime Devam Et", systemImage: "play.fill")
                                .frame(maxWidth: .infinity, minHeight: 44)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(Theme.gold)
                        .foregroundStyle(.black)
                    }
                    .padding(22)
                    .background(Theme.surface, in: RoundedRectangle(cornerRadius: 20))
                    Text("Öğrenme Yolun")
                        .font(.system(.title2, design: .serif, weight: .bold))
                    ForEach(AcademyCourse.all) { course in
                        HStack(spacing: 14) {
                            Image(systemName: course.symbol)
                                .font(.title2)
                                .foregroundStyle(Theme.gold)
                                .frame(width: 44, height: 44)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(course.title).font(.headline)
                                Text(course.summary).font(.footnote).foregroundStyle(.secondary)
                            }
                            Spacer(minLength: 0)
                        }
                        .padding(13)
                        .background(Theme.surface, in: RoundedRectangle(cornerRadius: 15))
                    }
                }
                .padding(16)
            }
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle("Satranç Akademisi")
        }
    }
}

struct CoursesView: View {
    @AppStorage("academy.completed") private var completed = ""
    var body: some View {
        NavigationStack {
            List {
                ForEach(AcademyCourse.all) { course in
                    Section {
                        ForEach(course.lessons) { lesson in
                            NavigationLink {
                                ChessLessonSession(lesson: lesson)
                            } label: {
                                HStack {
                                    Image(systemName: completed.split(separator: ",").contains(Substring(lesson.id)) ? "checkmark.seal.fill" : "play.circle")
                                        .foregroundStyle(Theme.gold)
                                    VStack(alignment: .leading, spacing: 5) {
                                        Text(lesson.title).font(.headline)
                                        Text(lesson.description).font(.caption).foregroundStyle(.secondary).lineLimit(2)
                                    }
                                }
                                .frame(minHeight: 44)
                            }
                        }
                    } header: {
                        Label(course.title, systemImage: course.symbol)
                    } footer: {
                        Text(course.summary)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.background)
            .navigationTitle("Satranç Dersleri")
        }
    }
}

struct PuzzlesView: View {
    var body: some View {
        NavigationStack {
            List(AcademyCourse.puzzles) { lesson in
                NavigationLink(destination: ChessLessonSession(lesson: lesson)) {
                    HStack(spacing: 12) {
                        Image(systemName: "puzzlepiece.fill").foregroundStyle(Theme.gold)
                        VStack(alignment: .leading) {
                            Text(lesson.title).font(.headline)
                            Text(lesson.goal).font(.caption).foregroundStyle(.secondary)
                        }
                    }.frame(minHeight: 44)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.background)
            .navigationTitle("Taktik Bulmacaları")
        }
    }
}

struct BotMenuView: View {
    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(BotDifficulty.allCases) { level in
                        NavigationLink(destination: ChessBotSession(difficulty: level)) {
                            HStack {
                                Image(systemName: "checkerboard.rectangle").foregroundStyle(Theme.gold)
                                VStack(alignment: .leading, spacing: 5) {
                                    Text(level.rawValue).font(.headline)
                                    Text(level.description).font(.caption).foregroundStyle(.secondary)
                                }
                            }.frame(minHeight: 50)
                        }
                    }
                } header: {
                    Text("Bilgisayara Karşı")
                } footer: {
                    Text("Seviyeler motorun arama derinliğine göre ayrılır. Resmî ELO değildir.")
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.background)
            .navigationTitle("Botla Oyna")
        }
    }
}

struct AcademyProfileView: View {
    @Binding var nickname: String
    @Binding var skill: String
    @AppStorage("academy.completed") private var completed = ""
    @State private var confirmErase = false
    @State private var showPrivacy = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Oyuncu") {
                    LabeledContent("Rumuz", value: nickname)
                    LabeledContent("Başlangıç", value: skill)
                    LabeledContent("Tamamlanan ders", value: "\(completed.split(separator: ",").count)")
                }
                Section("Gizlilik ve Destek") {
                    Button("Gizlilik bilgileri") { showPrivacy = true }
                    Link("Destek e-postası", destination: URL(string: "mailto:oguzhanozeren92@gmail.com")!)
                }
                Section {
                    Button("Yerel ilerlemeyi ve profili sil", role: .destructive) { confirmErase = true }
                } footer: {
                    Text("Bu ilk sürüm hesap oluşturmaz. Rumuz ve ders ilerlemesi yalnızca cihazda tutulur. Silme işlemi yerel verileri temizler.")
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.background)
            .navigationTitle("Profil ve Ayarlar")
            .alert("Verilerini sil?", isPresented: $confirmErase) {
                Button("Vazgeç", role: .cancel) { }
                Button("Sil", role: .destructive) {
                    completed = ""
                    skill = "Yeni başlıyorum"
                    nickname = ""
                }
            } message: {
                Text("Bu cihazdaki rumuz ve ders ilerlemesi silinir. İşlem geri alınamaz.")
            }
            .sheet(isPresented: $showPrivacy) {
                NavigationStack {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Bu prototipte giriş için e-posta veya telefon numarası istemiyoruz. Rumuz, seviye ve tamamlanan dersler yalnızca cihazdaki UserDefaults'a kaydedilir.")
                            Text("Reklam, analitik SDK, konum, kamera ve mikrofon izni kullanılmaz. Çevrimiçi hesap veya sunucu senkronizasyonu henüz yoktur.")
                            Text("Profil ve Ayarlar bölümünden yerel verilerini silebilirsin. Destek: oguzhanozeren92@gmail.com")
                        }
                        .font(.body)
                        .padding(20)
                    }
                    .navigationTitle("Gizlilik")
                    .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Kapat") { showPrivacy = false } } }
                }
            }
        }
    }
}