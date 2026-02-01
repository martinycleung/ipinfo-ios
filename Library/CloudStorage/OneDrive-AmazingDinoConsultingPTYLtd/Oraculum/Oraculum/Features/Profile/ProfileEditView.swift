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
