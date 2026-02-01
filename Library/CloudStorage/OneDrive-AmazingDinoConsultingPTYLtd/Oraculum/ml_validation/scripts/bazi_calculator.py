"""
BaZi Calculator - Python implementation for ML feature extraction
Calculates Four Pillars from Gregorian dates
"""

from dataclasses import dataclass
from enum import IntEnum
from typing import Optional, Tuple, List
import math
from datetime import datetime, date

class HeavenlyStem(IntEnum):
    JIA = 0    # 甲 Wood Yang
    YI = 1     # 乙 Wood Yin
    BING = 2   # 丙 Fire Yang
    DING = 3   # 丁 Fire Yin
    WU = 4     # 戊 Earth Yang
    JI = 5     # 己 Earth Yin
    GENG = 6   # 庚 Metal Yang
    XIN = 7    # 辛 Metal Yin
    REN = 8    # 壬 Water Yang
    GUI = 9    # 癸 Water Yin

class EarthlyBranch(IntEnum):
    ZI = 0     # 子 Rat
    CHOU = 1   # 丑 Ox
    YIN = 2    # 寅 Tiger
    MAO = 3    # 卯 Rabbit
    CHEN = 4   # 辰 Dragon
    SI = 5     # 巳 Snake
    WU = 6     # 午 Horse
    WEI = 7    # 未 Goat
    SHEN = 8   # 申 Monkey
    YOU = 9    # 酉 Rooster
    XU = 10    # 戌 Dog
    HAI = 11   # 亥 Pig

class FiveElement(IntEnum):
    WOOD = 0   # 木
    FIRE = 1   # 火
    EARTH = 2  # 土
    METAL = 3  # 金
    WATER = 4  # 水

# Element mappings
STEM_ELEMENTS = {
    HeavenlyStem.JIA: FiveElement.WOOD,
    HeavenlyStem.YI: FiveElement.WOOD,
    HeavenlyStem.BING: FiveElement.FIRE,
    HeavenlyStem.DING: FiveElement.FIRE,
    HeavenlyStem.WU: FiveElement.EARTH,
    HeavenlyStem.JI: FiveElement.EARTH,
    HeavenlyStem.GENG: FiveElement.METAL,
    HeavenlyStem.XIN: FiveElement.METAL,
    HeavenlyStem.REN: FiveElement.WATER,
    HeavenlyStem.GUI: FiveElement.WATER,
}

BRANCH_ELEMENTS = {
    EarthlyBranch.ZI: FiveElement.WATER,
    EarthlyBranch.CHOU: FiveElement.EARTH,
    EarthlyBranch.YIN: FiveElement.WOOD,
    EarthlyBranch.MAO: FiveElement.WOOD,
    EarthlyBranch.CHEN: FiveElement.EARTH,
    EarthlyBranch.SI: FiveElement.FIRE,
    EarthlyBranch.WU: FiveElement.FIRE,
    EarthlyBranch.WEI: FiveElement.EARTH,
    EarthlyBranch.SHEN: FiveElement.METAL,
    EarthlyBranch.YOU: FiveElement.METAL,
    EarthlyBranch.XU: FiveElement.EARTH,
    EarthlyBranch.HAI: FiveElement.WATER,
}

# Branch clashes (冲)
BRANCH_CLASHES = {
    EarthlyBranch.ZI: EarthlyBranch.WU,
    EarthlyBranch.CHOU: EarthlyBranch.WEI,
    EarthlyBranch.YIN: EarthlyBranch.SHEN,
    EarthlyBranch.MAO: EarthlyBranch.YOU,
    EarthlyBranch.CHEN: EarthlyBranch.XU,
    EarthlyBranch.SI: EarthlyBranch.HAI,
    EarthlyBranch.WU: EarthlyBranch.ZI,
    EarthlyBranch.WEI: EarthlyBranch.CHOU,
    EarthlyBranch.SHEN: EarthlyBranch.YIN,
    EarthlyBranch.YOU: EarthlyBranch.MAO,
    EarthlyBranch.XU: EarthlyBranch.CHEN,
    EarthlyBranch.HAI: EarthlyBranch.SI,
}

# Three Harmonies (三合)
THREE_HARMONIES = [
    ({EarthlyBranch.YIN, EarthlyBranch.WU, EarthlyBranch.XU}, FiveElement.FIRE),
    ({EarthlyBranch.SI, EarthlyBranch.YOU, EarthlyBranch.CHOU}, FiveElement.METAL),
    ({EarthlyBranch.SHEN, EarthlyBranch.ZI, EarthlyBranch.CHEN}, FiveElement.WATER),
    ({EarthlyBranch.HAI, EarthlyBranch.MAO, EarthlyBranch.WEI}, FiveElement.WOOD),
]

# Six Combinations (六合)
SIX_COMBINATIONS = [
    (EarthlyBranch.ZI, EarthlyBranch.CHOU, FiveElement.EARTH),
    (EarthlyBranch.YIN, EarthlyBranch.HAI, FiveElement.WOOD),
    (EarthlyBranch.MAO, EarthlyBranch.XU, FiveElement.FIRE),
    (EarthlyBranch.CHEN, EarthlyBranch.YOU, FiveElement.METAL),
    (EarthlyBranch.SI, EarthlyBranch.SHEN, FiveElement.WATER),
    (EarthlyBranch.WU, EarthlyBranch.WEI, FiveElement.FIRE),
]


@dataclass
class Pillar:
    stem: HeavenlyStem
    branch: EarthlyBranch

    @property
    def element(self) -> FiveElement:
        return STEM_ELEMENTS[self.stem]

    @property
    def cycle_index(self) -> int:
        """Index in the 60 Jiazi cycle (0-59)"""
        for i in range(60):
            if i % 10 == self.stem and i % 12 == self.branch:
                return i
        return 0


@dataclass
class FourPillarsChart:
    year_pillar: Pillar
    month_pillar: Pillar
    day_pillar: Pillar
    hour_pillar: Optional[Pillar] = None

    @property
    def day_master(self) -> HeavenlyStem:
        return self.day_pillar.stem

    @property
    def day_master_element(self) -> FiveElement:
        return STEM_ELEMENTS[self.day_master]

    @property
    def branches(self) -> List[EarthlyBranch]:
        branches = [self.year_pillar.branch, self.month_pillar.branch, self.day_pillar.branch]
        if self.hour_pillar:
            branches.append(self.hour_pillar.branch)
        return branches

    @property
    def stems(self) -> List[HeavenlyStem]:
        stems = [self.year_pillar.stem, self.month_pillar.stem, self.day_pillar.stem]
        if self.hour_pillar:
            stems.append(self.hour_pillar.stem)
        return stems


class BaZiCalculator:
    """Calculate Four Pillars from dates"""

    # Solar term dates (approximate, for month pillar calculation)
    # Each solar term is ~15 degrees of solar longitude
    SOLAR_TERMS_APPROX = [
        (2, 4),   # Li Chun - Start of Spring
        (3, 6),   # Jing Zhe
        (4, 5),   # Qing Ming
        (5, 6),   # Li Xia - Start of Summer
        (6, 6),   # Mang Zhong
        (7, 7),   # Xiao Shu
        (8, 8),   # Li Qiu - Start of Autumn
        (9, 8),   # Bai Lu
        (10, 8),  # Han Lu
        (11, 7),  # Li Dong - Start of Winter
        (12, 7),  # Da Xue
        (1, 6),   # Xiao Han
    ]

    def calculate(self, year: int, month: int, day: int, hour: Optional[int] = None) -> FourPillarsChart:
        """
        Calculate Four Pillars from Gregorian date

        Args:
            year: Gregorian year
            month: Month (1-12)
            day: Day of month
            hour: Hour (0-23), optional

        Returns:
            FourPillarsChart
        """
        year_pillar = self._calculate_year_pillar(year, month, day)
        month_pillar = self._calculate_month_pillar(year, month, day, year_pillar.stem)
        day_pillar = self._calculate_day_pillar(year, month, day)
        hour_pillar = self._calculate_hour_pillar(hour, day_pillar.stem) if hour is not None else None

        return FourPillarsChart(
            year_pillar=year_pillar,
            month_pillar=month_pillar,
            day_pillar=day_pillar,
            hour_pillar=hour_pillar
        )

    def _calculate_year_pillar(self, year: int, month: int, day: int) -> Pillar:
        """Calculate year pillar (adjusting for Li Chun)"""
        # Check if before Li Chun (approx Feb 4)
        if month < 2 or (month == 2 and day < 4):
            year -= 1

        # Calculate stem and branch
        # 1984 is Jia Zi year (index 0)
        cycle_index = (year - 1984) % 60
        if cycle_index < 0:
            cycle_index += 60

        stem = HeavenlyStem(cycle_index % 10)
        branch = EarthlyBranch(cycle_index % 12)

        return Pillar(stem=stem, branch=branch)

    def _calculate_month_pillar(self, year: int, month: int, day: int, year_stem: HeavenlyStem) -> Pillar:
        """Calculate month pillar using Five Tiger method"""
        # Determine lunar month based on solar terms
        lunar_month = self._get_lunar_month(month, day)

        # Month branch is fixed: Yin for month 1, Mao for month 2, etc.
        month_branch = EarthlyBranch((lunar_month + 1) % 12)

        # Calculate month stem using Five Tiger method
        # Based on year stem, determine starting stem for month 1 (Yin month)
        five_tiger_start = {
            HeavenlyStem.JIA: HeavenlyStem.BING,
            HeavenlyStem.JI: HeavenlyStem.BING,
            HeavenlyStem.YI: HeavenlyStem.WU,
            HeavenlyStem.GENG: HeavenlyStem.WU,
            HeavenlyStem.BING: HeavenlyStem.GENG,
            HeavenlyStem.XIN: HeavenlyStem.GENG,
            HeavenlyStem.DING: HeavenlyStem.REN,
            HeavenlyStem.REN: HeavenlyStem.REN,
            HeavenlyStem.WU: HeavenlyStem.JIA,
            HeavenlyStem.GUI: HeavenlyStem.JIA,
        }

        start_stem = five_tiger_start[year_stem]
        month_stem = HeavenlyStem((start_stem + lunar_month - 1) % 10)

        return Pillar(stem=month_stem, branch=month_branch)

    def _get_lunar_month(self, month: int, day: int) -> int:
        """Approximate lunar month from solar date"""
        # Simplified: each solar term roughly starts a new month
        for i, (term_month, term_day) in enumerate(self.SOLAR_TERMS_APPROX):
            if month < term_month or (month == term_month and day < term_day):
                return (i + 11) % 12 + 1  # Previous month
        return 12

    def _calculate_day_pillar(self, year: int, month: int, day: int) -> Pillar:
        """Calculate day pillar using Julian Day Number"""
        jdn = self._gregorian_to_jdn(year, month, day)

        # Reference: Jan 1, 1900 is Jia Zi day (cycle index 0)
        # JDN for Jan 1, 1900 is 2415021
        reference_jdn = 2415021
        cycle_index = (jdn - reference_jdn) % 60
        if cycle_index < 0:
            cycle_index += 60

        stem = HeavenlyStem(cycle_index % 10)
        branch = EarthlyBranch(cycle_index % 12)

        return Pillar(stem=stem, branch=branch)

    def _calculate_hour_pillar(self, hour: int, day_stem: HeavenlyStem) -> Pillar:
        """Calculate hour pillar using Five Rat method"""
        # Convert hour to Chinese hour (Shichen)
        # Zi: 23:00-01:00, Chou: 01:00-03:00, etc.
        shichen = ((hour + 1) // 2) % 12
        hour_branch = EarthlyBranch(shichen)

        # Five Rat method for hour stem
        five_rat_start = {
            HeavenlyStem.JIA: HeavenlyStem.JIA,
            HeavenlyStem.JI: HeavenlyStem.JIA,
            HeavenlyStem.YI: HeavenlyStem.BING,
            HeavenlyStem.GENG: HeavenlyStem.BING,
            HeavenlyStem.BING: HeavenlyStem.WU,
            HeavenlyStem.XIN: HeavenlyStem.WU,
            HeavenlyStem.DING: HeavenlyStem.GENG,
            HeavenlyStem.REN: HeavenlyStem.GENG,
            HeavenlyStem.WU: HeavenlyStem.REN,
            HeavenlyStem.GUI: HeavenlyStem.REN,
        }

        start_stem = five_rat_start[day_stem]
        hour_stem = HeavenlyStem((start_stem + shichen) % 10)

        return Pillar(stem=hour_stem, branch=hour_branch)

    def _gregorian_to_jdn(self, year: int, month: int, day: int) -> int:
        """Convert Gregorian date to Julian Day Number"""
        a = (14 - month) // 12
        y = year + 4800 - a
        m = month + 12 * a - 3

        jdn = day + (153 * m + 2) // 5 + 365 * y + y // 4 - y // 100 + y // 400 - 32045
        return jdn


class FeatureExtractor:
    """Extract ML features from BaZi chart"""

    def __init__(self):
        self.calculator = BaZiCalculator()

    def extract_features(self, chart: FourPillarsChart) -> dict:
        """Extract numerical features for ML training"""
        features = {}

        # Basic pillar features
        features['year_stem'] = int(chart.year_pillar.stem)
        features['year_branch'] = int(chart.year_pillar.branch)
        features['year_element'] = int(chart.year_pillar.element)

        features['month_stem'] = int(chart.month_pillar.stem)
        features['month_branch'] = int(chart.month_pillar.branch)
        features['month_element'] = int(chart.month_pillar.element)

        features['day_stem'] = int(chart.day_pillar.stem)
        features['day_branch'] = int(chart.day_pillar.branch)
        features['day_element'] = int(chart.day_pillar.element)

        if chart.hour_pillar:
            features['hour_stem'] = int(chart.hour_pillar.stem)
            features['hour_branch'] = int(chart.hour_pillar.branch)
            features['hour_element'] = int(chart.hour_pillar.element)
            features['has_hour'] = 1
        else:
            features['hour_stem'] = -1
            features['hour_branch'] = -1
            features['hour_element'] = -1
            features['has_hour'] = 0

        # Day Master features
        features['day_master'] = int(chart.day_master)
        features['day_master_element'] = int(chart.day_master_element)
        features['day_master_is_yang'] = 1 if chart.day_master % 2 == 0 else 0

        # Element counts
        element_counts = self._count_elements(chart)
        for element in FiveElement:
            features[f'element_count_{element.name.lower()}'] = element_counts[element]

        # Branch combination features
        branches = chart.branches
        features['has_three_harmony'] = self._has_three_harmony(branches)
        features['three_harmony_count'] = self._count_three_harmonies(branches)
        features['has_six_combination'] = self._has_six_combination(branches)
        features['six_combination_count'] = self._count_six_combinations(branches)

        # Clash features
        features['clash_count'] = self._count_clashes(branches)
        features['year_day_clash'] = 1 if self._is_clash(chart.year_pillar.branch, chart.day_pillar.branch) else 0
        features['month_day_clash'] = 1 if self._is_clash(chart.month_pillar.branch, chart.day_pillar.branch) else 0

        # Cycle indices
        features['year_cycle_index'] = chart.year_pillar.cycle_index
        features['month_cycle_index'] = chart.month_pillar.cycle_index
        features['day_cycle_index'] = chart.day_pillar.cycle_index

        # Day Master strength indicators
        features['dm_strength_score'] = self._calculate_dm_strength(chart)

        return features

    def _count_elements(self, chart: FourPillarsChart) -> dict:
        """Count occurrences of each element in the chart"""
        counts = {element: 0 for element in FiveElement}

        for stem in chart.stems:
            counts[STEM_ELEMENTS[stem]] += 1

        for branch in chart.branches:
            counts[BRANCH_ELEMENTS[branch]] += 1

        return counts

    def _has_three_harmony(self, branches: List[EarthlyBranch]) -> int:
        """Check if any complete three harmony exists"""
        branch_set = set(branches)
        for harmony_branches, _ in THREE_HARMONIES:
            if harmony_branches.issubset(branch_set):
                return 1
        return 0

    def _count_three_harmonies(self, branches: List[EarthlyBranch]) -> int:
        """Count complete three harmonies"""
        branch_set = set(branches)
        count = 0
        for harmony_branches, _ in THREE_HARMONIES:
            if harmony_branches.issubset(branch_set):
                count += 1
        return count

    def _has_six_combination(self, branches: List[EarthlyBranch]) -> int:
        """Check if any six combination exists"""
        for i in range(len(branches)):
            for j in range(i + 1, len(branches)):
                for b1, b2, _ in SIX_COMBINATIONS:
                    if (branches[i] == b1 and branches[j] == b2) or \
                       (branches[i] == b2 and branches[j] == b1):
                        return 1
        return 0

    def _count_six_combinations(self, branches: List[EarthlyBranch]) -> int:
        """Count six combinations"""
        count = 0
        for i in range(len(branches)):
            for j in range(i + 1, len(branches)):
                for b1, b2, _ in SIX_COMBINATIONS:
                    if (branches[i] == b1 and branches[j] == b2) or \
                       (branches[i] == b2 and branches[j] == b1):
                        count += 1
        return count

    def _is_clash(self, b1: EarthlyBranch, b2: EarthlyBranch) -> bool:
        """Check if two branches clash"""
        return BRANCH_CLASHES.get(b1) == b2

    def _count_clashes(self, branches: List[EarthlyBranch]) -> int:
        """Count clashes among branches"""
        count = 0
        for i in range(len(branches)):
            for j in range(i + 1, len(branches)):
                if self._is_clash(branches[i], branches[j]):
                    count += 1
        return count

    def _calculate_dm_strength(self, chart: FourPillarsChart) -> float:
        """Calculate Day Master strength score (0-1)"""
        dm_element = chart.day_master_element

        # Count supporting elements (same element + producing element)
        support = 0
        control = 0

        producing_element = FiveElement((dm_element - 1) % 5)  # Element that produces DM
        controlled_element = FiveElement((dm_element + 2) % 5)  # Element DM controls
        controlling_element = FiveElement((dm_element + 3) % 5)  # Element that controls DM

        element_counts = self._count_elements(chart)

        support = element_counts[dm_element] + element_counts[producing_element]
        control = element_counts[controlled_element] + element_counts[controlling_element]

        total = support + control
        if total == 0:
            return 0.5

        return support / total


if __name__ == "__main__":
    # Test calculation
    calc = BaZiCalculator()
    extractor = FeatureExtractor()

    # Test with a known date
    chart = calc.calculate(1990, 6, 15, 12)
    print(f"Year Pillar: {chart.year_pillar.stem.name}-{chart.year_pillar.branch.name}")
    print(f"Month Pillar: {chart.month_pillar.stem.name}-{chart.month_pillar.branch.name}")
    print(f"Day Pillar: {chart.day_pillar.stem.name}-{chart.day_pillar.branch.name}")
    print(f"Hour Pillar: {chart.hour_pillar.stem.name}-{chart.hour_pillar.branch.name}")
    print(f"\nDay Master: {chart.day_master.name} ({chart.day_master_element.name})")

    features = extractor.extract_features(chart)
    print(f"\nFeatures: {features}")
