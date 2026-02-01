//
//  ProfileSetupView.swift
//  Oraculum
//
//  Initial profile setup and onboarding
//

import SwiftUI
import SwiftData
import CoreLocation
import OraculumCore

struct ProfileSetupView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var localization: LocalizationManager
    let onComplete: () -> Void

    @State private var name: String = ""
    @State private var selectedGender: Gender = .male
    @State private var birthDate: Date = Calendar.current.date(byAdding: .year, value: -30, to: Date()) ?? Date()
    @State private var birthCity: String = ""
    @State private var birthLatitude: Double = 22.3  // Default: Hong Kong
    @State private var birthLongitude: Double = 114.2
    @State private var birthTimezone: String = "Asia/Hong_Kong"
    @State private var industry: String = ""
    @State private var currentStep = 0

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

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Progress indicator
                ProgressView(value: Double(currentStep + 1), total: 4)
                    .padding(.horizontal)
                    .padding(.top, 8)

                // Step content
                Group {
                    switch currentStep {
                    case 0: welcomeStep
                    case 1: nameStep
                    case 2: birthStep
                    case 3: industryStep
                    default: welcomeStep
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .navigationTitle(localization.localize("setup.welcome"))
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // MARK: - Step 0: Welcome

    private var welcomeStep: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "sparkles")
                .font(.system(size: 60))
                .foregroundStyle(.blue)

            Text(localization.localize("app.tagline"))
                .font(.title3)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)

            Text(localization.localize("setup.description"))
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Spacer()

            Button(action: { currentStep = 1 }) {
                Text(localization.localize("setup.getStarted"))
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
    }

    // MARK: - Step 1: Name & Gender

    private var nameStep: some View {
        VStack(spacing: 24) {
            Spacer()

            Text(localization.localize("setup.whatCallYou"))
                .font(.title2)
                .fontWeight(.semibold)

            TextField(localization.localize("setup.yourName"), text: $name)
                .textFieldStyle(.roundedBorder)
                .font(.body)
                .padding(.horizontal, 32)

            // Gender Selection (required for BaZi Luck Pillar calculation)
            VStack(spacing: 12) {
                Text(localization.localize("setup.selectGender"))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                HStack(spacing: 16) {
                    ForEach(Gender.allCases, id: \.self) { gender in
                        Button(action: { selectedGender = gender }) {
                            HStack {
                                Image(systemName: gender == .male ? "person.fill" : "person.fill")
                                Text(localization.localize(gender.localizationKey))
                            }
                            .font(.subheadline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(selectedGender == gender ? Color.blue : Color(.secondarySystemBackground))
                            .foregroundStyle(selectedGender == gender ? .white : .primary)
                            .cornerRadius(10)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 32)

                Text(localization.localize("setup.genderNote"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Spacer()

            Button(action: { currentStep = 2 }) {
                Text(localization.localize("setup.continue"))
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(name.isEmpty ? Color.gray : Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .disabled(name.isEmpty)
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
    }

    // MARK: - Step 2: Birth Info

    private var birthStep: some View {
        VStack(spacing: 0) {
            Text(localization.localize("setup.whenWhereBorn"))
                .font(.title2)
                .fontWeight(.semibold)
                .padding(.top, 16)

            Text(localization.localize("setup.birthEssential"))
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(.top, 4)

            List {
                Section {
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
                }

                Section {
                    TextField(localization.localize("setup.city"), text: $birthCity)

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
            }
            .listStyle(.insetGrouped)

            Button(action: { currentStep = 3 }) {
                Text(localization.localize("setup.continue"))
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
    }

    // MARK: - Step 3: Industry

    private var industryStep: some View {
        VStack(spacing: 16) {
            Text(localization.localize("setup.yourIndustry"))
                .font(.title2)
                .fontWeight(.semibold)
                .padding(.top, 16)

            Text(localization.localize("setup.industryHelp"))
                .font(.subheadline)
                .foregroundStyle(.secondary)

            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(industries, id: \.self) { ind in
                        Button(action: { industry = ind }) {
                            Text(localization.localize(ind))
                                .font(.subheadline)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(industry == ind ? Color.blue : Color(.secondarySystemBackground))
                                .foregroundStyle(industry == ind ? .white : .primary)
                                .cornerRadius(10)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)
            }

            Button(action: { saveProfile() }) {
                Text(localization.localize("setup.completeSetup"))
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(industry.isEmpty ? Color.gray : Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .disabled(industry.isEmpty)
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
    }

    // MARK: - Save Profile

    private func saveProfile() {
        // Get localized industry name for display
        let industryName = localization.localize(industry)

        let profile = UserProfile(
            name: name,
            gender: selectedGender,
            relationship: .selfUser,
            birthDate: birthDate,
            birthLatitude: birthLatitude,
            birthLongitude: birthLongitude,
            birthTimezone: birthTimezone,
            industry: industryName
        )

        modelContext.insert(profile)

        // Calculate and cache Ba Zi chart
        Task {
            let calculator = FourPillarsCalculator()
            let chart = await calculator.calculate(
                birthDate: birthDate,
                birthLocation: CLLocationCoordinate2D(
                    latitude: birthLatitude,
                    longitude: birthLongitude
                ),
                timezone: TimeZone(identifier: birthTimezone) ?? .current
            )
            profile.updateChart(chart)

            try? modelContext.save()
            await MainActor.run {
                onComplete()
            }
        }
    }
}

#Preview {
    ProfileSetupView(onComplete: {})
        .environmentObject(LocalizationManager.shared)
        .modelContainer(for: [UserProfile.self])
}
