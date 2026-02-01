# BaZi ML Validation System Design

## Overview

A hybrid machine learning system to validate and enhance BaZi predictions using 650K+ historical records from CBDB (China Biographical Database) plus modern user-contributed data.

## Architecture

### Data Sources
1. **CBDB SQLite** - 650K historical records (Year/Month/Day precision)
2. **Wikidata API** - Supplementary data for cross-reference
3. **Modern User Collection** - 4-pillar data with birth hour (future)

### ML Models (Ensemble)
1. **XGBoost** - Career outcomes, longevity prediction
2. **Transformer Neural Network** - Overall fortune patterns
3. **Bayesian Network** - Relationship timing, causal inference

### Validation Metrics
1. **Event Prediction** - Predict year of major events (±2 year accuracy)
2. **Binary Classification** - High office achievement, longevity (F1 > 0.7)
3. **Ranking Correlation** - Date auspiciousness ranking (Spearman ρ > 0.5)

## Implementation Phases

### Phase 1: Data Pipeline
- Download CBDB SQLite database
- Build ETL pipeline for date conversion
- Extract BaZi features from historical dates
- Label life events (career appointments, death dates)

### Phase 2: Model Training
- Feature engineering for 3-pillar analysis
- Train XGBoost for career/longevity
- Train Transformer for pattern recognition
- Train Bayesian Network for timing
- Ensemble integration with confidence weighting

### Phase 3: iOS Integration
- Export models to CoreML format
- Create MLValidationEngine in Swift
- Integrate with existing ScoringSystem
- Add confidence scores to predictions

### Phase 4: Modern Data Collection
- Add consent-based birth time collection UI
- Store 4-pillar data with life event tracking
- Continuous model improvement pipeline

## Feature Engineering

### Input Features (per person)
- Year Pillar: stem (0-9), branch (0-11), element (0-4)
- Month Pillar: stem, branch, element
- Day Pillar: stem, branch, element (Day Master)
- Day Master Strength: weak/balanced/strong
- Branch Combinations: 三合, 三会, 六合 presence
- Branch Conflicts: 冲, 刑, 破, 害 counts
- Void Positions: 空亡 in chart
- Nayin Elements: 纳音 for each pillar
- Useful God: element and validation status

### Output Labels
- Career Peak Age (regression)
- Highest Office Achieved (classification)
- Death Age (regression)
- Number of Recorded Appointments (regression)
- Social Connection Count (regression)

## Technology Stack

- **Python**: pandas, scikit-learn, xgboost, pytorch, pgmpy (Bayesian)
- **Swift**: CoreML, CreateML for on-device inference
- **Database**: SQLite for CBDB, SwiftData for app storage
- **Export**: coremltools for model conversion

## Success Criteria

1. Event prediction accuracy > 60% within ±2 years
2. Binary classification F1 > 0.7
3. Ranking correlation ρ > 0.5
4. All models run on-device < 100ms inference time
5. 94+ existing unit tests continue to pass
