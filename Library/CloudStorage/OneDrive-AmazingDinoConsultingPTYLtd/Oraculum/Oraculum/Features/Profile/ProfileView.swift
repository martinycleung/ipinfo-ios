//
//  ProfileView.swift
//  Oraculum
//
//  User profile view with Ba Zi chart display
//

import SwiftUI
import SwiftData
import OraculumCore

struct ProfileView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var localization: LocalizationManager
    @Query private var profiles: [UserProfile]

    @State private var showingEditSheet = false
    @State private var luckPillars: LuckPillarResult?

    var body: some View {
        NavigationStack {
            ScrollView {
                if let profile = profiles.first {
                    VStack(spacing: 24) {
                        // Profile Header
                        profileHeader(profile)

                        // Ba Zi Chart
                        baZiChartSection(profile)

                        // Day Master Analysis
                        dayMasterSection(profile)

                        // Useful God
                        if let usefulGod = profile.usefulGod {
                            usefulGodSection(usefulGod)
                        }

                        // Luck Pillars (大运) - Changes with gender
                        luckPillarsSection(profile)

                        // Settings
                        settingsSection
                    }
                    .padding()
                    .task {
                        calculateLuckPillars(for: profile)
                    }
                    .onChange(of: profile.gender) { _, _ in
                        calculateLuckPillars(for: profile)
                    }
                    .onChange(of: profile.birthDate) { _, _ in
                        calculateLuckPillars(for: profile)
                    }
                } else {
                    ContentUnavailableView(
                        "No Profile",
                        systemImage: "person.crop.circle.badge.questionmark",
                        description: Text("Please set up your profile to get started.")
                    )
                }
            }
            .navigationTitle(localization.localize("profile.title"))
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(localization.localize("profile.edit")) {
                        showingEditSheet = true
                    }
                }
            }
            .sheet(isPresented: $showingEditSheet) {
                if let profile = profiles.first {
                    ProfileEditView(profile: profile)
                }
            }
        }
    }

    private func profileHeader(_ profile: UserProfile) -> some View {
        VStack(spacing: 12) {
            // Avatar
            ZStack {
                Circle()
                    .fill(Color.blue.gradient)
                    .frame(width: 100, height: 100)

                Text(String(profile.name.prefix(1)))
                    .font(.system(size: 44, weight: .semibold))
                    .foregroundStyle(.white)
            }

            Text(profile.name)
                .font(.title2)
                .fontWeight(.semibold)

            if let industry = profile.industry {
                Text(industry)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func baZiChartSection(_ profile: UserProfile) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(localization.localize("profile.yourBaZiChart"))
                .font(.headline)

            // Four Pillars Grid
            HStack(spacing: 0) {
                PillarView(title: localization.localize("pillar.hour"), pillar: profile.hourPillar)
                Divider()
                PillarView(title: localization.localize("pillar.day"), pillar: profile.dayPillar, isHighlighted: true)
                Divider()
                PillarView(title: localization.localize("pillar.month"), pillar: profile.monthPillar)
                Divider()
                PillarView(title: localization.localize("pillar.year"), pillar: profile.yearPillar)
            }
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private func dayMasterSection(_ profile: UserProfile) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(localization.localize("profile.dayMaster"))
                .font(.headline)

            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(elementColor(profile.dayPillar.stem.element).gradient)
                        .frame(width: 60, height: 60)

                    Text(profile.dayPillar.stem.chineseName)
                        .font(.title)
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(profile.dayPillar.stem.pinyin)
                        .font(.title3)
                        .fontWeight(.medium)

                    Text("\(profile.dayPillar.stem.polarity.englishName) \(profile.dayPillar.stem.element.englishName)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Text(localization.localize("profile.dayMasterDescription"))
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private func usefulGodSection(_ usefulGod: UsefulGod) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(localization.localize("profile.usefulGod"))
                .font(.headline)

            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(elementColor(usefulGod.element).gradient)
                        .frame(width: 50, height: 50)

                    Text(usefulGod.element.chineseName)
                        .font(.title2)
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(usefulGod.element.englishName)
                        .font(.title3)
                        .fontWeight(.medium)

                    Text(localization.localize("profile.usefulGodDescription", usefulGod.element.englishName))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private var settingsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(localization.localize("profile.settings"))
                .font(.headline)

            VStack(spacing: 0) {
                NavigationLink {
                    NotificationsSettingsView()
                } label: {
                    SettingsRow(icon: "bell", title: localization.localize("profile.notifications"), hasChevron: true)
                }
                .buttonStyle(.plain)
                Divider().padding(.leading, 44)

                NavigationLink {
                    LanguageSettingsView()
                } label: {
                    SettingsRow(icon: "globe", title: localization.localize("profile.language"), hasChevron: true)
                }
                .buttonStyle(.plain)
                Divider().padding(.leading, 44)

                NavigationLink {
                    PrivacySettingsView()
                } label: {
                    SettingsRow(icon: "lock.shield", title: localization.localize("profile.privacy"), hasChevron: true)
                }
                .buttonStyle(.plain)
                Divider().padding(.leading, 44)

                NavigationLink {
                    AboutView()
                } label: {
                    SettingsRow(icon: "info.circle", title: localization.localize("profile.about"), hasChevron: true)
                }
                .buttonStyle(.plain)
            }
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private func elementColor(_ element: FiveElement) -> Color {
        switch element {
        case .wood: return .green
        case .fire: return .red
        case .earth: return .brown
        case .metal: return .gray
        case .water: return .blue
        }
    }

    // MARK: - Luck Pillars Section (大运)

    private func luckPillarsSection(_ profile: UserProfile) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(localization.localize("profile.luckPillars"))
                    .font(.headline)
                Spacer()
                if let luckPillars = luckPillars {
                    Text(luckPillars.direction.chineseName)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(6)
                }
            }

            if let luckPillars = luckPillars {
                // Display direction info
                HStack(spacing: 4) {
                    Image(systemName: luckPillars.direction == .forward ? "arrow.right" : "arrow.left")
                        .font(.caption)
                    Text(localization.localize("profile.luckStartAge", luckPillars.startAge))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.bottom, 4)

                // Scrollable Luck Pillars
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(luckPillars.luckPillars.prefix(8)) { luckPillar in
                            LuckPillarCard(
                                luckPillar: luckPillar,
                                currentAge: currentAge(from: profile.birthDate),
                                elementColor: elementColor
                            )
                        }
                    }
                    .padding(.vertical, 4)
                }
            } else {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text(localization.localize("profile.calculating"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func calculateLuckPillars(for profile: UserProfile) {
        let calculator = LuckPillarCalculator()
        let result = calculator.calculate(
            chart: profile.baZiChart,
            gender: profile.genderType,
            birthDate: profile.birthDate
        )
        luckPillars = result
    }

    private func currentAge(from birthDate: Date) -> Int {
        let calendar = Calendar(identifier: .gregorian)
        let components = calendar.dateComponents([.year], from: birthDate, to: Date())
        return components.year ?? 0
    }
}

// MARK: - Luck Pillar Card

struct LuckPillarCard: View {
    let luckPillar: LuckPillar
    let currentAge: Int
    let elementColor: (FiveElement) -> Color

    private var isCurrent: Bool {
        currentAge >= luckPillar.startAge && currentAge < luckPillar.endAge
    }

    var body: some View {
        VStack(spacing: 4) {
            // Age range
            Text("\(luckPillar.startAge)-\(luckPillar.endAge - 1)")
                .font(.caption2)
                .foregroundStyle(.secondary)

            // Stem
            Text(luckPillar.pillar.stem.chineseName)
                .font(.title3)
                .fontWeight(.medium)

            // Branch
            Text(luckPillar.pillar.branch.chineseName)
                .font(.title3)
                .fontWeight(.medium)

            // Element indicator
            Circle()
                .fill(elementColor(luckPillar.pillar.stem.element).gradient)
                .frame(width: 8, height: 8)
        }
        .frame(width: 50)
        .padding(.vertical, 8)
        .padding(.horizontal, 4)
        .background(isCurrent ? Color.blue.opacity(0.15) : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isCurrent ? Color.blue : Color.clear, lineWidth: 2)
        )
    }
}

struct PillarView: View {
    let title: String
    let pillar: Pillar
    var isHighlighted: Bool = false

    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)

            VStack(spacing: 4) {
                Text(pillar.stem.chineseName)
                    .font(.title2)
                    .fontWeight(.medium)

                Text(pillar.branch.chineseName)
                    .font(.title2)
                    .fontWeight(.medium)
            }
            .padding(.vertical, 8)

            Text(pillar.branch.zodiacAnimalChinese)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(isHighlighted ? Color.blue.opacity(0.1) : Color.clear)
    }
}

struct SettingsRow: View {
    let icon: String
    let title: String
    var hasChevron: Bool = false

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(.blue)
                .frame(width: 24)

            Text(title)

            Spacer()

            if hasChevron {
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding()
    }
}

#Preview {
    ProfileView()
        .environmentObject(LocalizationManager.shared)
        .modelContainer(for: [UserProfile.self])
}
