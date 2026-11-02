import SwiftUI
import UIKit

@main
struct SatrancAkademisiApp: App {
    init() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(red: 0.035, green: 0.075, blue: 0.12, alpha: 1)
        appearance.shadowColor = UIColor(red: 0.4, green: 0.32, blue: 0.18, alpha: 0.45)
        let active = UIColor(red: 0.97, green: 0.80, blue: 0.53, alpha: 1)
        let inactive = UIColor(red: 0.54, green: 0.63, blue: 0.68, alpha: 1)
        appearance.stackedLayoutAppearance.selected.iconColor = active
        appearance.stackedLayoutAppearance.normal.iconColor = inactive
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: active]
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: inactive]
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }

    var body: some Scene {
        WindowGroup {
            AcademyRootView()
                .preferredColorScheme(.dark)
                .tint(Theme.gold)
        }
    }
}

enum Theme {
    static let background = Color(red: 0.024, green: 0.050, blue: 0.095)
    static let surface = Color(red: 0.075, green: 0.145, blue: 0.212)
    static let gold = Color(red: 0.90, green: 0.69, blue: 0.40)
    static let cream = Color(red: 0.98, green: 0.94, blue: 0.86)
}

enum AcademyTab: String, CaseIterable, Identifiable {
    case home = "Ana Sayfa", lessons = "Dersler", puzzles = "Bulmaca", play = "Oyna", profile = "Profil"
    var id: String { rawValue }
    var chessPiece: PremiumChessPiece {
        switch self {
        case .home: return .king
        case .lessons: return .pawn
        case .puzzles: return .knight
        case .play: return .rook
        case .profile: return .queen
        }
    }
    var tabImage: UIImage { ChessTabArt.image(for: chessPiece) }
}

struct AcademyRootView: View {
    @AppStorage("academy.nickname") private var nickname = ""
    @AppStorage("academy.skill") private var skill = "Yeni başlıyorum"
    @State private var selectedTab: AcademyTab = .home

    var body: some View {
        TabView(selection: $selectedTab) {
            AcademyHomeView(nickname: nickname.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Misafir" : nickname) {
                selectedTab = .lessons
            }
            .tabItem {
                    Label {
                        Text(AcademyTab.home.rawValue)
                    } icon: {
                        Image(uiImage: AcademyTab.home.tabImage)
                    }
                }
            .tag(AcademyTab.home)

            CoursesView()
                .tabItem {
                    Label {
                        Text(AcademyTab.lessons.rawValue)
                    } icon: {
                        Image(uiImage: AcademyTab.lessons.tabImage)
                    }
                }
                .tag(AcademyTab.lessons)

            PuzzlesView()
                .tabItem {
                    Label {
                        Text(AcademyTab.puzzles.rawValue)
                    } icon: {
                        Image(uiImage: AcademyTab.puzzles.tabImage)
                    }
                }
                .tag(AcademyTab.puzzles)

            BotMenuView()
                .tabItem {
                    Label {
                        Text(AcademyTab.play.rawValue)
                    } icon: {
                        Image(uiImage: AcademyTab.play.tabImage)
                    }
                }
                .tag(AcademyTab.play)

            AcademyProfileView(nickname: $nickname, skill: $skill)
                .tabItem {
                    Label {
                        Text(AcademyTab.profile.rawValue)
                    } icon: {
                        Image(uiImage: AcademyTab.profile.tabImage)
                    }
                }
                .tag(AcademyTab.profile)
        }
        .background(Theme.background.ignoresSafeArea())
    }
}

struct AcademyHomeView: View {
    let nickname: String
    let onLearning: () -> Void

    @AppStorage("academy.completed") private var completed = ""
    @AppStorage("academy.beginnerJourneyDone") private var started = false
    @AppStorage("academy.scenarios.completed") private var completedScenarios = ""

    private var totalLessons: Int { AcademyCourse.all.reduce(0) { $0 + $1.lessons.count } }
    private var finishedLessons: Int {
        let ids = Set(completed.split(separator: ",").map(String.init))
        return AcademyCourse.all.reduce(0) { $0 + $1.lessons.filter { ids.contains($0.id) }.count }
    }
    private var finishedScenarios: Int {
        Set(completedScenarios.split(separator: ",").map(String.init)).count
    }
    private let grid = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    var body: some View {
        NavigationStack {
            ZStack {
                PremiumBackdrop()
                ScrollView {
                    VStack(alignment: .leading, spacing: 21) {
                        topIdentity
                        featureHero

                        HStack(spacing: 9) {
                            PremiumStat(value: String(finishedLessons) + "/" + String(totalLessons),
                                        label: "Tamamlanan ders", piece: .pawn)
                            PremiumStat(value: String(finishedScenarios) + "/7",
                                        label: "Senaryo", piece: .knight)
                            PremiumStat(value: "3", label: "Bot seviyesi", piece: .rook)
                        }

                        NavigationLink {
                            SimulationHubView()
                        } label: {
                            PremiumPanel(accent: true) {
                                HStack(alignment: .center, spacing: 14) {
                                    ChessPieceBadge(piece: .knight, size: 64, highlighted: true)
                                    VStack(alignment: .leading, spacing: 5) {
                                        Text("SENARYO MODU")
                                            .font(.system(size: 10, weight: .heavy))
                                            .tracking(1.5)
                                            .foregroundStyle(Theme.gold)
                                        Text("Yaşayarak öğren")
                                            .font(.system(.title3, design: .serif, weight: .bold))
                                            .foregroundStyle(Theme.cream)
                                        Text("Hamleni yap, koçun her kararını açıklasın.")
                                            .font(.caption)
                                            .foregroundStyle(Theme.pale)
                                            .multilineTextAlignment(.leading)
                                    }
                                    Spacer(minLength: 0)
                                    Image(systemName: "arrow.up.right")
                                        .font(.subheadline.weight(.bold))
                                        .foregroundStyle(Theme.gold)
                                }
                            }
                        }
                        .buttonStyle(.plain)

                        PremiumSectionHeading(title: "Öğrenme Yolun",
                                              eyebrow: "ADIM ADIM İLERLE",
                                              count: String(AcademyCourse.all.count) + " bölüm")
                        LazyVGrid(columns: grid, spacing: 12) {
                            ForEach(AcademyCourse.all) { course in
                                NavigationLink {
                                    PremiumCourseDetailView(course: course)
                                } label: {
                                    courseTile(course)
                                }
                                .buttonStyle(.plain)
                            }
                        }

                        Text("Şampiyonlar hamleleri ezberlemez; neden yaptıklarını öğrenir.")
                            .font(.footnote.italic())
                            .foregroundStyle(Theme.pale)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 18)
                    .padding(.bottom, 24)
                    .frame(maxWidth: 720)
                    .frame(maxWidth: .infinity)
                }
            }
            .navigationBarHidden(true)
        }
    }

    private var topIdentity: some View {
        HStack(spacing: 12) {
            ChessPieceBadge(piece: .king, size: 47, highlighted: true)
            VStack(alignment: .leading, spacing: 3) {
                Text("SATRANÇ AKADEMİSİ")
                    .font(.system(.subheadline, design: .serif, weight: .heavy))
                    .tracking(1.2)
                    .foregroundStyle(Theme.champagne)
                Text("Düşün. Hamle yap. Öğren.")
                    .font(.caption)
                    .foregroundStyle(Theme.pale)
            }
            Spacer(minLength: 6)
            Text("♛")
                .font(.system(size: 24, design: .serif))
                .foregroundStyle(Theme.gold)
                .frame(width: 40, height: 40)
                .background(Theme.gold.opacity(0.12), in: Circle())
                .accessibilityHidden(true)
        }
    }

    private var featureHero: some View {
        PremiumPanel(accent: true, padding: 22) {
            VStack(alignment: .leading, spacing: 15) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 7) {
                        Text(started ? "ÖĞRENMEYE DEVAM" : "İLK HAMLE SENİN")
                            .font(.system(size: 10, weight: .heavy))
                            .tracking(1.9)
                            .foregroundStyle(Theme.champagne)
                        Text(started ? "Tahtaya geri dön." : "Bir hamleyle başlar.")
                            .font(.system(size: 32, weight: .bold, design: .serif))
                            .minimumScaleFactor(0.75)
                            .foregroundStyle(Theme.cream)
                        Text("Merhaba, " + nickname + "! Satrancı hiç bilmesen de burada sıfırdan öğrenebilirsin.")
                            .font(.subheadline)
                            .foregroundStyle(Theme.pale)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer(minLength: 4)
                    Text("♞")
                        .font(.system(size: 78, design: .serif))
                        .foregroundStyle(Theme.metal)
                        .shadow(color: Theme.gold.opacity(0.22), radius: 10, y: 5)
                        .accessibilityHidden(true)
                }
                HStack(spacing: 9) {
                    Image(systemName: "sparkle")
                        .foregroundStyle(Theme.gold)
                    Text("Ücretsiz · Rumuz zorunlu değil · Süre baskısı yok")
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(Theme.pale)
                }

                NavigationLink {
                    BeginnerJourneyView()
                } label: {
                    HStack {
                        Text(started ? "Kaldığın yerden başla" : "Sıfırdan Satranç Öğren")
                        Spacer()
                        Image(systemName: "arrow.right")
                    }
                    .padding(.horizontal, 16)
                }
                .buttonStyle(PremiumPrimaryButtonStyle())

                Button(action: onLearning) {
                    HStack {
                        Image(systemName: "square.grid.2x2")
                        Text("Tüm dersleri keşfet")
                    }
                }
                .buttonStyle(PremiumPrimaryButtonStyle(secondary: true))
            }
        }
    }

    private func coursePiece(_ id: String) -> PremiumChessPiece {
        switch id {
        case "ilk-adim", "baslangic": return .pawn
        case "kurallar": return .king
        case "plan": return .bishop
        case "taktikler": return .knight
        case "acilislar": return .queen
        case "oyunsonu": return .rook
        default: return .pawn
        }
    }

    private func courseTile(_ course: AcademyCourse) -> some View {
        PremiumPanel(padding: 13) {
            VStack(alignment: .leading, spacing: 11) {
                HStack {
                    ChessPieceBadge(piece: coursePiece(course.id), size: 46)
                    Spacer(minLength: 0)
                    Image(systemName: "arrow.up.right")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(Theme.gold)
                }
                Text(course.title)
                    .font(.system(.subheadline, design: .serif, weight: .bold))
                    .foregroundStyle(Theme.cream)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                Text(course.summary)
                    .font(.caption2)
                    .foregroundStyle(Theme.pale)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Spacer(minLength: 0)
                Text(String(course.lessons.count) + " DERS")
                    .font(.system(size: 10, weight: .heavy))
                    .tracking(1)
                    .foregroundStyle(Theme.gold)
            }
            .frame(maxWidth: .infinity, minHeight: 165, alignment: .topLeading)
        }
    }
}

struct PremiumCourseDetailView: View {
    let course: AcademyCourse
    @AppStorage("academy.completed") private var completed = ""

    private var icon: PremiumChessPiece {
        switch course.id {
        case "ilk-adim", "baslangic": return .pawn
        case "kurallar": return .king
        case "plan": return .bishop
        case "taktikler": return .knight
        case "acilislar": return .queen
        case "oyunsonu": return .rook
        default: return .pawn
        }
    }

    var body: some View {
        ZStack {
            PremiumBackdrop()
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    PremiumPanel(accent: true) {
                        HStack(spacing: 15) {
                            ChessPieceBadge(piece: icon, size: 74, highlighted: true)
                            VStack(alignment: .leading, spacing: 6) {
                                Text(course.title)
                                    .font(.system(.title2, design: .serif, weight: .bold))
                                    .foregroundStyle(Theme.cream)
                                Text(course.summary)
                                    .font(.subheadline)
                                    .foregroundStyle(Theme.pale)
                            }
                        }
                    }
                    ForEach(course.lessons.indices, id: \.self) { index in
                        let lesson = course.lessons[index]
                        NavigationLink {
                            ChessLessonSession(lesson: lesson)
                        } label: {
                            PremiumPanel(padding: 14) {
                                HStack(spacing: 13) {
                                    Text(String(format: "%02d", index + 1))
                                        .font(.title3.monospacedDigit().weight(.bold))
                                        .foregroundStyle(Theme.champagne)
                                        .frame(width: 36)
                                    VStack(alignment: .leading, spacing: 5) {
                                        Text(lesson.title)
                                            .font(.headline)
                                            .foregroundStyle(Theme.cream)
                                        Text(lesson.goal)
                                            .font(.caption)
                                            .foregroundStyle(Theme.pale)
                                            .multilineTextAlignment(.leading)
                                    }
                                    Spacer(minLength: 0)
                                    Image(systemName: completed.split(separator: ",").contains(Substring(lesson.id))
                                          ? "checkmark.seal.fill" : "chevron.right")
                                        .foregroundStyle(Theme.gold)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(16)
                .frame(maxWidth: 720)
                .frame(maxWidth: .infinity)
            }
        }
        .navigationTitle(course.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct CoursesView: View {
    private func piece(for id: String) -> PremiumChessPiece {
        switch id {
        case "ilk-adim", "baslangic": return .pawn
        case "kurallar": return .king
        case "plan": return .bishop
        case "taktikler": return .knight
        case "acilislar": return .queen
        case "oyunsonu": return .rook
        default: return .pawn
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                PremiumBackdrop()
                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        PremiumSectionHeading(title: "Satranç Dersleri",
                                              eyebrow: "KENDİ HIZINDA ÖĞREN",
                                              count: "43 ders")
                        NavigationLink {
                            BeginnerJourneyView()
                        } label: {
                            PremiumPanel(accent: true) {
                                HStack(spacing: 14) {
                                    ChessPieceBadge(piece: .pawn, size: 58, highlighted: true)
                                    VStack(alignment: .leading, spacing: 6) {
                                        Text("Sıfırdan başla")
                                            .font(.system(.title3, design: .serif, weight: .bold))
                                            .foregroundStyle(Theme.cream)
                                        Text("Tahtayı ve taşları tanı, ilk hamleni yap.")
                                            .font(.caption)
                                            .foregroundStyle(Theme.pale)
                                    }
                                    Spacer(minLength: 0)
                                    Image(systemName: "chevron.right")
                                        .foregroundStyle(Theme.gold)
                                }
                            }
                        }
                        .buttonStyle(.plain)

                        NavigationLink {
                            SimulationHubView()
                        } label: {
                            PremiumPanel {
                                HStack(spacing: 14) {
                                    ChessPieceBadge(piece: .knight, size: 58)
                                    VStack(alignment: .leading, spacing: 6) {
                                        Text("Senaryolu Simülasyon")
                                            .font(.headline)
                                            .foregroundStyle(Theme.cream)
                                        Text("Hamleni yap, koçun analiz etsin.")
                                            .font(.caption)
                                            .foregroundStyle(Theme.pale)
                                    }
                                    Spacer(minLength: 0)
                                    Image(systemName: "chevron.right")
                                        .foregroundStyle(Theme.gold)
                                }
                            }
                        }
                        .buttonStyle(.plain)

                        PremiumSectionHeading(title: "Eğitim Bölümleri",
                                              eyebrow: "TEMELDEN USTALIĞA",
                                              count: String(AcademyCourse.all.count))
                            .padding(.top, 9)

                        ForEach(AcademyCourse.all) { course in
                            NavigationLink {
                                PremiumCourseDetailView(course: course)
                            } label: {
                                PremiumPanel {
                                    HStack(spacing: 14) {
                                        ChessPieceBadge(piece: piece(for: course.id), size: 56)
                                        VStack(alignment: .leading, spacing: 5) {
                                            Text(course.title)
                                                .font(.system(.headline, design: .serif))
                                                .foregroundStyle(Theme.cream)
                                            Text(course.summary)
                                                .font(.caption)
                                                .foregroundStyle(Theme.pale)
                                                .multilineTextAlignment(.leading)
                                                .lineLimit(2)
                                            Text(String(course.lessons.count) + " DERS")
                                                .font(.system(size: 10, weight: .heavy))
                                                .tracking(1)
                                                .foregroundStyle(Theme.gold)
                                        }
                                        Spacer(minLength: 0)
                                        Image(systemName: "chevron.right")
                                            .foregroundStyle(Theme.gold)
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                        }

                        PremiumSectionHeading(title: "Satranç Kütüphanesi",
                                              eyebrow: "ÖĞRENDİKÇE KEŞFET")
                            .padding(.top, 8)
                        NavigationLink {
                            MoveNotationGuideView()
                        } label: {
                            libraryRow(piece: .rook, title: "Hamlelerin Dili",
                                       subtitle: "e4, Af3, O-O, şah ve mat işaretleri")
                        }
                        .buttonStyle(.plain)
                        NavigationLink {
                            TacticGlossaryView()
                        } label: {
                            libraryRow(piece: .bishop, title: "Taktik Sözlüğü",
                                       subtitle: "Çatal, açmaz, şiş ve daha fazlası")
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(16)
                    .frame(maxWidth: 720)
                    .frame(maxWidth: .infinity)
                }
            }
            .navigationTitle("Dersler")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func libraryRow(piece: PremiumChessPiece, title: String,
                            subtitle: String) -> some View {
        PremiumPanel {
            HStack(spacing: 14) {
                ChessPieceBadge(piece: piece, size: 51)
                VStack(alignment: .leading, spacing: 5) {
                    Text(title).font(.headline).foregroundStyle(Theme.cream)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(Theme.pale)
                }
                Spacer(minLength: 0)
                Image(systemName: "arrow.up.right").foregroundStyle(Theme.gold)
            }
        }
    }
}

struct PuzzlesView: View {
    var body: some View {
        NavigationStack {
            ZStack {
                PremiumBackdrop()
                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        PremiumPanel(accent: true) {
                            HStack(spacing: 15) {
                                ChessPieceBadge(piece: .knight, size: 72, highlighted: true)
                                VStack(alignment: .leading, spacing: 7) {
                                    Text("TAKTİK ARENASI")
                                        .font(.system(size: 10, weight: .heavy))
                                        .tracking(1.4)
                                        .foregroundStyle(Theme.gold)
                                    Text("Hamleyi sen bul.")
                                        .font(.system(.title2, design: .serif, weight: .bold))
                                        .foregroundStyle(Theme.cream)
                                    Text("Yanlış yapmak serbest. Her bulmacanın mantığını tahtada keşfet.")
                                        .font(.caption).foregroundStyle(Theme.pale)
                                }
                            }
                        }

                        PremiumSectionHeading(title: "Bulmacalar",
                                              eyebrow: "DÜŞÜN · BUL · ÖĞREN",
                                              count: String(AcademyCourse.puzzles.count))
                        ForEach(AcademyCourse.puzzles.indices, id: \.self) { index in
                            let lesson = AcademyCourse.puzzles[index]
                            NavigationLink {
                                ChessLessonSession(lesson: lesson)
                            } label: {
                                PremiumPanel(padding: 15) {
                                    HStack(spacing: 13) {
                                        ChessPieceBadge(
                                            piece: index.isMultiple(of: 2) ? .knight : .bishop,
                                            size: 53
                                        )
                                        VStack(alignment: .leading, spacing: 6) {
                                            Text(lesson.title)
                                                .font(.headline)
                                                .foregroundStyle(Theme.cream)
                                            Text(lesson.goal)
                                                .font(.caption)
                                                .foregroundStyle(Theme.pale)
                                                .multilineTextAlignment(.leading)
                                                .lineLimit(2)
                                        }
                                        Spacer(minLength: 0)
                                        Image(systemName: "arrow.up.right")
                                            .foregroundStyle(Theme.gold)
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(16)
                    .frame(maxWidth: 720)
                    .frame(maxWidth: .infinity)
                }
            }
            .navigationTitle("Bulmacalar")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct BotMenuView: View {
    var body: some View {
        NavigationStack {
            ZStack {
                PremiumBackdrop()
                ScrollView {
                    VStack(alignment: .leading, spacing: 15) {
                        PremiumPanel(accent: true) {
                            HStack(spacing: 16) {
                                ChessPieceBadge(piece: .king, size: 77, highlighted: true)
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("ŞAHA MEYDAN OKU")
                                        .font(.system(size: 10, weight: .heavy))
                                        .tracking(1.4)
                                        .foregroundStyle(Theme.gold)
                                    Text("Botla karşılaş")
                                        .font(.system(.title2, design: .serif, weight: .bold))
                                        .foregroundStyle(Theme.cream)
                                    Text("Öğrendiklerini gerçek hamlelerle dene.")
                                        .font(.caption)
                                        .foregroundStyle(Theme.pale)
                                }
                            }
                        }
                        PremiumSectionHeading(title: "Zorluk Seç",
                                              eyebrow: "SANA UYGUN RAKİP",
                                              count: "3 seviye")
                        ForEach(BotDifficulty.allCases.indices, id: \.self) { index in
                            let level = BotDifficulty.allCases[index]
                            NavigationLink {
                                ChessBotSession(difficulty: level)
                            } label: {
                                PremiumPanel {
                                    HStack(spacing: 13) {
                                        ChessPieceBadge(
                                            piece: [.pawn, .rook, .queen][index],
                                            size: 60,
                                            highlighted: index == 0
                                        )
                                        VStack(alignment: .leading, spacing: 6) {
                                            Text(level.rawValue)
                                                .font(.system(.title3, design: .serif, weight: .bold))
                                                .foregroundStyle(Theme.cream)
                                            Text(level.description)
                                                .font(.caption)
                                                .foregroundStyle(Theme.pale)
                                                .multilineTextAlignment(.leading)
                                        }
                                        Spacer(minLength: 0)
                                        Image(systemName: "chevron.right")
                                            .foregroundStyle(Theme.gold)
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                        }
                        Text("Bot seviyeleri eğitim amaçlıdır; resmî ELO gücü değildir.")
                            .font(.footnote).foregroundStyle(Theme.pale)
                            .padding(.horizontal, 3)
                    }
                    .padding(16)
                    .frame(maxWidth: 720)
                    .frame(maxWidth: .infinity)
                }
            }
            .navigationTitle("Botla Oyna")
            .navigationBarTitleDisplayMode(.inline)
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
                    TextField("Rumuz (isteğe bağlı)", text: $nickname)
                        .textContentType(.nickname)
                        .autocorrectionDisabled()
                    Text("Rumuz yazmak zorunda değilsin. Boş bırakırsan Misafir olarak devam edersin.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    LabeledContent("Başlangıç", value: skill)
                    LabeledContent("Tamamlanan ders", value: "\(completed.split(separator: ",").count)")
                }
                Section("Gizlilik ve Destek") {
                    Link("Gizlilik Politikası", destination: URL(string: "https://github.com/oguzhanozeren92-debug/new2/blob/main/satranc-akademisi-ios/GIZLILIK_POLITIKASI.md")!)
                    Link("Destek ve İletişim", destination: URL(string: "https://github.com/oguzhanozeren92-debug/new2/blob/main/satranc-akademisi-ios/DESTEK.md")!)
                    Button("Cihazdaki veri kullanımı") { showPrivacy = true }
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