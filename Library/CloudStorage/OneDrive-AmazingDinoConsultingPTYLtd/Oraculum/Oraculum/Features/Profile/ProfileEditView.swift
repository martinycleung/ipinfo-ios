//
//  ProfileEditView.swift
//  Oraculum
//
//  Edit existing user profile
//

import SwiftUI
import SwiftData
import CoreLocation
import OraculumCore

struct ProfileEditView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var localization: LocalizationManager

    @Bindable var profile: UserProfile

    @State private var name: String
    @State private var selectedGender: Gender
    @State private var birthDate: Date
    @State private var birthTimezone: String
    @State private var industry: String
    @State private var isSaving = false

    // Live BaZi preview
    @State private var previewChart: FourPillarsChart?
    @State private var isCalculating = false

    private let industries = [
        "industry.technology",
        "industry.finance",
        "industry.consulting",
        "industry.realEstate",
        "industry.healthcare",
        "industry.legal",
        "industry.manufacturing",
        "industry.retail",
        "industry.other"
    ]

    init(profile: UserProfile) {
        self.profile = profile
        _name = State(initialValue: profile.name)
        _selectedGender = State(initialValue: profile.genderType)
        _birthDate = State(initialValue: profile.birthDate)
        _birthTimezone = State(initialValue: profile.birthTimezone)
        _industry = State(initialValue: profile.industry ?? "")
    }

    var body: some View {
        NavigationStack {
            List {
                Section(localization.localize("profile.personalInfo")) {
                    TextField(localization.localize("setup.yourName"), text: $name)

                    Picker(localization.localize("profile.gender"), selection: $selectedGender) {
                        ForEach(Gender.allCases, id: \.self) { gender in
                            Text(localization.localize(gender.localizationKey)).tag(gender)
                        }
                    }
                }

                Section(localization.localize("profile.birthInfo")) {
                    DatePicker(
                        localization.localize("setup.birthDate"),
                        selection: $birthDate,
                        in: ...Date(),
                        displayedComponents: .date
                    )

                    DatePicker(
                        localization.localize("setup.birthTime"),
                        selection: $birthDate,
                        displayedComponents: .hourAndMinute
                    )

                    Picker(localization.localize("setup.timezone"), selection: $birthTimezone) {
                        Text("Hong Kong").tag("Asia/Hong_Kong")
                        Text("Shanghai").tag("Asia/Shanghai")
                        Text("Singapore").tag("Asia/Singapore")
                        Text("Tokyo").tag("Asia/Tokyo")
                        Text("Melbourne").tag("Australia/Melbourne")
                        Text("London").tag("Europe/London")
                        Text("New York").tag("America/New_York")
                    }
                }

                // Live BaZi Preview Section
                Section(localization.localize("profile.baziPreview")) {
                    if isCalculating {
                        HStack {
                            Spacer()
                            ProgressView()
                                .scaleEffect(0.8)
                            Text(localization.localize("profile.calculating"))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Spacer()
                        }
                        .padding(.vertical, 8)
                    } else if let chart = previewChart {
                        // Four Pillars Preview Grid
                        HStack(spacing: 0) {
                            PreviewPillarCell(
                                title: localization.localize("pillar.hour"),
                                pillar: chart.hourPillar
                            )
                            Divider()
                            PreviewPillarCell(
                                title: localization.localize("pillar.day"),
                                pillar: chart.dayPillar,
                                isHighlighted: true
                            )
                            Divider()
                            PreviewPillarCell(
                                title: localization.localize("pillar.month"),
                                pillar: chart.monthPillar
                            )
                            Divider()
                            PreviewPillarCell(
                                title: localization.localize("pillar.year"),
                                pillar: chart.yearPillar
                            )
                        }
                        .frame(height: 100)
                    }
                }

                Section(localization.localize("profile.industry")) {
                    ForEach(industries, id: \.self) { ind in
                        Button {
                            industry = ind
                        } label: {
                            HStack {
                                Text(localization.localize(ind))
                                    .foregroundStyle(.primary)
                                Spacer()
                                if industry == ind || localization.localize(ind) == profile.industry {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.blue)
                                }
                            }
                        }
                    }
                }
            }
            .task {
                await calculatePreview()
            }
            .onChange(of: birthDate) { _, _ in
                Task {
                    await calculatePreview()
                }
            }
            .onChange(of: birthTimezone) { _, _ in
                Task {
                    await calculatePreview()
                }
            }
            .navigationTitle(localization.localize("profile.editProfile"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(localization.localize("action.cancel")) {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    if isSaving {
                        ProgressView()
                    } else {
                        Button(localization.localize("action.save")) {
                            saveProfile()
                        }
                        .disabled(name.isEmpty)
                    }
                }
            }
        }
    }

    private func saveProfile() {
        isSaving = true

        // Update profile
        profile.name = name
        profile.gender = selectedGender.rawValue
        profile.birthDate = birthDate
        profile.birthTimezone = birthTimezone
        profile.industry = industry.isEmpty ? nil : localization.localize(industry)

        // Recalculate Ba Zi chart
        Task {
            let calculator = FourPillarsCalculator()
            let chart = await calculator.calculate(
                birthDate: birthDate,
                birthLocation: CLLocationCoordinate2D(
                    latitude: profile.birthLatitude,
                    longitude: profile.birthLongitude
                ),
                timezone: TimeZone(identifier: birthTimezone) ?? .current
            )
            profile.updateChart(chart)

            try? modelContext.save()
            await MainActor.run {
                isSaving = false
                dismiss()
            }
        }
    }

    private func calculatePreview() async {
        isCalculating = true

        let calculator = FourPillarsCalculator()
        let chart = await calculator.calculate(
            birthDate: birthDate,
            birthLocation: CLLocationCoordinate2D(
                latitude: profile.birthLatitude,
                longitude: profile.birthLongitude
            ),
            timezone: TimeZone(identifier: birthTimezone) ?? .current
        )

        await MainActor.run {
            previewChart = chart
            isCalculating = false
        }
    }
}

// MARK: - Preview Pillar Cell

struct PreviewPillarCell: View {
    let title: String
    let pillar: Pillar
    var isHighlighted: Bool = false

    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)

            Text(pillar.stem.chineseName)
                .font(.title3)
                .fontWeight(.medium)

            Text(pillar.branch.chineseName)
                .font(.title3)
                .fontWeight(.medium)

            Text(pillar.branch.zodiacAnimalChinese)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(isHighlighted ? Color.blue.opacity(0.1) : Color.clear)
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: UserProfile.self, configurations: config)
    let profile = UserProfile(
        name: "Test User",
        relationship: .selfUser,
        birthDate: Date(),
        birthLatitude: 22.3,
        birthLongitude: 114.2,
        birthTimezone: "Asia/Hong_Kong",
        industry: "Technology"
    )
    container.mainContext.insert(profile)

    return ProfileEditView(profile: profile)
        .environmentObject(LocalizationManager.shared)
        .modelContainer(container)
}
