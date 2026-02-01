# Oraculum iOS App - Claude Development Guide

## Project Overview

Oraculum (神谕/神諭) is an iOS app for auspicious date selection (择日/擇日) based on traditional Chinese metaphysics, specifically Ba Zi (八字) Four Pillars astrology. The app provides professional-grade date selection for business executives, using astronomically-precise calculations rather than simplified lookup tables.

### Target Audience
- Business executives making strategic decisions
- Individuals planning important life events (marriage, moving, contracts)
- Anyone interested in traditional Chinese date selection

## Project Structure

```
Oraculum/
├── App/                           # Xcode app target (OraculumApp.xcodeproj)
│   ├── OraculumAppMain.swift      # App entry point with SwiftData
│   └── Assets.xcassets/           # App icons and assets
├── Oraculum/                      # Main source code
│   ├── Core/                      # Core calculation engine
│   │   ├── Engine/BaZi/           # BaZi calculation modules
│   │   │   ├── BranchCombinations.swift   # 三合, 三会, 六合, 冲刑破害
│   │   │   ├── VoidCalculator.swift       # 空亡 void positions
│   │   │   ├── NayinCalculator.swift      # 纳音 Five Elements
│   │   │   ├── LuckPillarCalculator.swift # 大运 10-year cycles
│   │   │   ├── UsefulGodCalculator.swift  # 用神 with validation
│   │   │   ├── DayMasterStrengthCalculator.swift
│   │   │   ├── ChartPatternAnalyzer.swift
│   │   │   └── ClimateAdjustmentCalculator.swift
│   │   ├── AI/                    # LLM integration (iOS 18+)
│   │   │   ├── LLMService.swift          # Protocol and context types
│   │   │   ├── AppleFoundationModelService.swift  # Apple Foundation Models
│   │   │   ├── PromptBuilder.swift       # Builds consultation prompts
│   │   │   └── ConsultantPersona.swift   # System prompts for personas
│   │   └── Logic/                 # Calculators and algorithms
│   │       ├── FourPillarsCalculator.swift
│   │       ├── SolarTermCalculator.swift
│   │       ├── DayOfficerCalculator.swift
│   │       ├── LunarStarsCalculator.swift
│   │       └── Selection/
│   │           ├── SelectionEngine.swift
│   │           ├── ScoringSystem.swift   # Advanced utility-based scoring
│   │           └── MLValidationEngine.swift  # ML-enhanced predictions
│   ├── Data/Models/               # SwiftData models
│   │   ├── UserProfile.swift
│   │   ├── FamilyMember.swift
│   │   └── DayAnalysisCache.swift
│   ├── Features/                  # UI components
│   │   ├── Boardroom/             # Today's overview dashboard
│   │   ├── Calendar/              # Date selection calendar
│   │   ├── Profile/               # User profile management
│   │   └── Settings/              # App settings
│   └── Resources/Localizations/   # i18n strings
│       ├── en.lproj/
│       ├── zh-Hans.lproj/         # Simplified Chinese
│       └── zh-Hant.lproj/         # Traditional Chinese
├── OraculumTests/                 # Unit tests
├── ml_validation/                 # ML validation system (Python)
│   ├── scripts/
│   │   ├── bazi_calculator.py     # Python BaZi feature extraction
│   │   ├── cbdb_pipeline.py       # CBDB historical data pipeline
│   │   ├── train_models.py        # XGBoost, Transformer, Bayesian Network training
│   │   └── export_coreml.py       # CoreML model export
│   └── requirements.txt
└── Package.swift                  # Swift Package for core library
```

## Architecture

### Core Calculation Stack

1. **FourPillarsCalculator** - Calculates the four pillars (year, month, day, hour) using:
   - VSOP87 astronomical theory for solar longitude
   - Julian Day calculations for day pillar
   - True Solar Time corrections based on location
   - Five Tiger and Five Rat derivation methods

2. **SolarTermCalculator** - Determines current solar term for accurate month pillar

3. **DayOfficerCalculator** - Calculates the 12 Day Officers (建除十二神)

4. **LunarStarsCalculator** - Calculates active Lunar Stars (神煞)

5. **SelectionEngine** - Orchestrates analysis for single days and date ranges

6. **ScoringSystem** - Advanced utility-based scoring algorithm with qualitative ratings

### Advanced BaZi Analysis (v1.1)

7. **BranchCombinationAnalyzer** - Comprehensive branch relationship analysis:
   - Three Harmonies (三合) - Elemental frame combinations
   - Three Meetings (三会) - Seasonal element combinations
   - Six Combinations (六合) - Branch pair combinations
   - Clashes (冲), Harms (害), Punishments (刑), Destructions (破)

8. **VoidCalculator** - Kong Wang (空亡) void position analysis:
   - Calculates void branches from 60 Jiazi cycle
   - Void severity assessment
   - UsefulGod void status checking

9. **NayinCalculator** - Nayin (纳音) Five Elements system:
   - 30 Nayin types mapped to 60 Jiazi
   - Strength and compatibility analysis
   - Chart-level Nayin assessment

10. **LuckPillarCalculator** - 10-year luck cycle (大运) calculation:
    - Direction based on year stem polarity and gender
    - Luck pillar favorability analysis
    - Current luck pillar identification

11. **UsefulGodCalculator** - Enhanced Useful God (用神) analysis:
    - Three traditional methods: Strength Balance, Pattern, Climate
    - Validation checks: 透干, 有根, 被冲, 空亡, 有护
    - Effectiveness scoring with confidence adjustment

### Scoring Algorithm (Utility Vector Approach)

The scoring system uses context-aware "utility" scoring rather than general luck assessment:

#### Level 1: Year Breaker (岁破/Sui Po) Detection
- Triggered when: Day Branch clashes with Annual Branch
- For constructive activities (contracts, openings): Heavy penalty (-40), context: "Hidden risks in agreements"
- For destructive activities (demolition, clearing): Bonus (+10), context: "Strong clearing energy"

#### Level 2: Personal Clash / Fan Yin (犯寅)
- Triggered when: Day Branch clashes with User's Day Master Branch
- This is the ONLY instant fail condition
- Context: "Personal safety risk - avoid travel and high-risk activities"

#### Level 3: Day Officer Contextualization
- Officers can be "compromised" during Year Breaker clashes
- Example: Kai (Open) day during Year Breaker = "Deceptive Open"

#### Level 4: Lunar Star Processing
- Heavenly Virtue (天德) nullifies minor negative stars
- Major inauspicious stars still apply penalties

#### Level 5: Non-Critical Clashes and Penalties
- Month clashes, year clashes (except Fan Yin)
- Three penalties, six harms

#### Level 6: Useful God (喜用神) Resonance
- If day's element supports user's Useful God: bonus
- If day's element clashes user's Useful God: penalty
- UsefulGod validation affects scoring weight (透干, 有根, 被冲, 空亡)

#### Level 7: Branch Combination Analysis
- Three Harmonies/Meetings provide bonuses
- Clashes and punishments apply penalties
- Void positions reduce element effectiveness

### ML Validation Engine (v1.2)

The system includes ML-enhanced validation using historical data from CBDB (China Biographical Database) with 650K+ records:

12. **MLValidationEngine** - CoreML-ready ML predictions:
    - Feature extraction from BaZi charts (BaZiMLFeatures)
    - Rule-based predictions (fallback) with fortune level estimation
    - Score enhancement blending traditional + ML predictions
    - Three Harmony, Six Combination, clash detection

**Python ML Pipeline** (`ml_validation/scripts/`):
- **bazi_calculator.py**: Python BaZi feature extraction matching Swift
- **cbdb_pipeline.py**: Downloads and processes CBDB SQLite database
- **train_models.py**: Trains XGBoost (career/longevity), Transformer (patterns), Bayesian Network (timing)
- **export_coreml.py**: Exports models to CoreML format

**ML Features Extracted:**
- Pillar stems, branches, elements (12 features)
- Day Master element and strength
- Element counts (wood, fire, earth, metal, water)
- Combination flags (Three Harmony, Six Combination)
- Clash count

**Validation Metrics:**
- Event prediction: ±2 years accuracy
- Binary classification: F1 > 0.7 target
- Ranking correlation: Spearman ρ > 0.5

### Qualitative Rating System (v1.1)
Traditional Chinese ratings alongside numeric scores:
- `大吉` (Supremely Auspicious) - Excellent conditions
- `吉` (Auspicious) - Favorable conditions
- `小吉` (Slightly Auspicious) - Mildly positive
- `平` (Neutral) - Neither good nor bad
- `小凶` (Slightly Inauspicious) - Minor concerns
- `凶` (Inauspicious) - Unfavorable conditions
- `大凶` (Supremely Inauspicious) - Avoid completely

### Visual Severity Levels
- `.critical` - Red (instant fail conditions)
- `.highWarning` - Dark orange
- `.warning` - Orange
- `.neutral` - Gray
- `.good` - Green
- `.excellent` - Gold

## Key Domain Models

### Pillar
```swift
struct Pillar {
    let stem: HeavenlyStem    // 天干 (Jia, Yi, Bing, Ding, etc.)
    let branch: EarthlyBranch // 地支 (Zi, Chou, Yin, Mao, etc.)
}
```

### Activity Categories
- **Constructive**: signContract, negotiation, openBusiness, marriage, etc.
- **Destructive**: demolition, funeral, lawsuit, etc.
- **Medical**: surgery, startTreatment, checkup
- **Travel**: longTravel, businessTrip, relocation

### DayOfficer (建除十二神)
Jian, Chu, Man, Ping, Ding, Zhi, Po, Wei, Cheng, Shou, Kai, Bi

### LunarStar Types
- **Auspicious**: TianDe (天德), YueDe (月德), GuiRen (贵人), etc.
- **Inauspicious**: SuiPo (岁破), SanSha (三煞), WuGui (五鬼), etc.

## Data Models (SwiftData)

### UserProfile
```swift
@Model class UserProfile {
    var name: String
    var birthDate: Date
    var birthTime: Date
    var birthTimezone: String
    var industry: String?
    var baziChartData: Data?  // Encoded FourPillarsChart
}
```

### FamilyMember
For group date selection with multiple stakeholders.

### DayAnalysisCache
Caches analysis results to avoid recalculation.

## Localization

Three languages supported:
- English (en)
- Simplified Chinese (zh-Hans)
- Traditional Chinese (zh-Hant)

Key localization patterns:
- Use `LocalizationManager.shared.localizedString(_:)` for runtime strings
- Use Chinese bracket quotes `「」` instead of ASCII `"` inside localized strings
- All activity names, day officers, elements, and stars are localized

## Build & Deploy

### Build Commands
```bash
# Build for simulator
xcodebuild -project OraculumApp.xcodeproj -scheme Oraculum \
    -destination 'platform=iOS Simulator,name=iPhone 16 Pro' build

# Build for device (requires signing)
xcodebuild -project OraculumApp.xcodeproj -scheme Oraculum \
    -destination 'generic/platform=iOS' \
    -allowProvisioningUpdates build

# Run tests
swift test
```

### Deploy to Physical Device
```bash
# Install to connected iPhone
xcrun devicectl device install app \
    --device <DEVICE_UDID> \
    /path/to/DerivedData/.../Oraculum.app
```

### Code Signing
- Development Team: `YBL5AWWBNL`
- Bundle ID: `com.oraculum.app`
- Automatic signing enabled

## Testing

### Test Organization
- `FourPillarsCalculatorTests` - Pillar calculation accuracy
- `SolarTermCalculatorTests` - Solar term detection
- `DayOfficerCalculatorTests` - Day officer calculations
- `ScoringSystemTests` - Scoring algorithm verification
- `MLValidationEngineTests` - ML feature extraction and predictions (16 tests)

### Key Test Cases
- Year Breaker penalty for constructive activities
- Year Breaker bonus for destructive activities
- Personal Clash (Fan Yin) instant fail
- Heavenly Virtue nullification of negative stars
- Score bounds (0-100)

## UI Components

### Main Views
- **BoardroomView** - Today's dashboard with overall score and recommendations
- **StrategicCalendarView** - Heatmap calendar with date selection
- **ProfileView** - User Ba Zi chart display and settings
- **ProfileEditView** - Edit user profile information
- **DayDetailView** - Detailed analysis for selected date with professional insights

### Professional Insights Display (v1.3)
The scoring system generates personalized professional insights that are displayed in the UI:

**ScoringResult Properties:**
- `professionalTitle` - Localized title (e.g., "insight.personalClash.title")
- `professionalInsight` - Detailed personalized advice
- `alternativeDateSuggestion` - Suggestion for better dates (if applicable)
- `hasPersonalClash` - Critical warning flag
- `isYearBreaker` - Year breaker warning flag

**UI Components Displaying Insights:**
- `DayDetailView` - Shows full insight section with icon, title, and advice
- `DayBriefCard` - Shows condensed insight on Boardroom dashboard
- `BoardroomViewModel.getTodayRecommendation()` - Returns professional insight text

**Insight Icons by Severity:**
- Personal Clash: `person.crop.circle.badge.exclamationmark` (red)
- Year Breaker: `exclamationmark.shield` (orange)
- Caution/Avoid: `lightbulb.fill` (orange/red)
- Good/Excellent: `sparkles` (green/yellow)

### LLM Infrastructure (iOS 18+, Prepared)
The app includes LLM infrastructure for future enhanced personalization:

**Components:**
- `LLMService.swift` - Protocol defining LLM interface
- `AppleFoundationModelService.swift` - Apple Foundation Models integration
- `FallbackLLMService.swift` - Rule-based fallback for non-iOS 18 devices
- `PromptBuilder.swift` - Builds consultation prompts from BaZi context
- `ConsultantPersona.swift` - System prompts for different consultant personas

**Status:** Infrastructure ready, UI integration pending for iOS 18+ devices

### Settings Views
- **NotificationSettingsView** - Push notification preferences
- **PrivacySettingsView** - Data collection and privacy controls
- **AboutView** - Algorithm and methodology description
- **PrivacyPolicyView** - Full privacy policy
- **TermsOfServiceView** - Terms of service
- **LanguageSettingsView** - Language switching

## Common Issues & Solutions

### Localization File Syntax Errors
- Use Chinese quotes `「」` not ASCII `"` inside string values
- Ensure all lines end with semicolon `;`
- Validate with: `plutil -lint Localizable.strings`

### Warning String Localization
Warnings from ScoringResult may be:
- Localization keys with "warning." prefix (e.g., "warning.yearBreaker")
- Localization keys with "score." prefix (e.g., "score.instantFail")
- Plain text strings (legacy/backwards compatibility)

Always check both prefixes when localizing warnings:
```swift
private func localizedWarning(_ warning: String) -> String {
    if warning.hasPrefix("warning.") || warning.hasPrefix("score.") {
        return localization.localize(warning)
    }
    return warning  // Return as-is for plain text
}
```

### SwiftData Concurrency
- SelectionEngine is an `actor` for thread safety
- Use `await` when calling engine methods
- ViewModels marked with `@MainActor`

### Sheet Presentation
- Use `@State private var showingSheet = false`
- Attach `.sheet(isPresented:)` modifier
- Pass `@Bindable` for SwiftData models in sheets

## Version History

### Current Features (v1.3)
- Complete Ba Zi chart calculation
- Advanced utility-based scoring algorithm
- Date selection for 30+ activity types
- Group selection for multiple users
- Multi-language support (EN, ZH-Hans, ZH-Hant)
- Professional insight messaging with UI display
- Privacy-first local data storage
- Branch Combinations (三合, 三会, 六合, 冲刑破害)
- Void (空亡) position analysis
- Nayin (纳音) Five Elements system
- Luck Pillars (大运) 10-year cycle calculation
- UsefulGod validation (透干, 有根, 被冲, 空亡, 有护)
- Qualitative rating system (大吉 to 大凶)
- ML Validation Engine with CoreML support
- Python ML pipeline for CBDB historical data training
- Feature extraction: Three Harmony, Six Combination, clash detection
- **NEW:** Professional insights displayed in DayDetailView and DayBriefCard
- **NEW:** BoardroomViewModel uses personalized insights for recommendations
- **NEW:** Warning localization supports both "warning." and "score." prefixes
- **NEW:** LLM infrastructure prepared (iOS 18+ ready)
- **NEW:** 110 unit tests passing

### v1.2 (ML Validation Engine)
- ML Validation Engine with CoreML support
- Python ML pipeline for CBDB historical data training
- Feature extraction: Three Harmony, Six Combination, clash detection

### v1.1 (Advanced BaZi Analysis)
- Branch Combinations and Void analysis
- Nayin Five Elements system
- Luck Pillars calculation
- UsefulGod validation enhancements
- Qualitative rating system

### v1.0 (Initial Release)
- Core Ba Zi calculation engine
- Basic scoring algorithm
- Activity-based date selection
