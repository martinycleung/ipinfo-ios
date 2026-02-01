"""
CBDB Data Pipeline
Downloads and processes China Biographical Database for BaZi ML training
"""

import os
import sqlite3
import requests
import zipfile
from io import BytesIO
from pathlib import Path
from typing import Optional, List, Dict, Tuple
from dataclasses import dataclass
from datetime import datetime
import pandas as pd
from tqdm import tqdm

from bazi_calculator import BaZiCalculator, FeatureExtractor, FourPillarsChart


# CBDB Download URL (GitHub release)
CBDB_URL = "https://github.com/cbdb-project/cbdb_sqlite/raw/main/cbdb_sqlite.db.zip"
CBDB_BACKUP_URL = "https://dataverse.harvard.edu/api/access/datafile/6290809"  # Harvard Dataverse


@dataclass
class Person:
    """Represents a historical person from CBDB"""
    person_id: int
    name: str
    birth_year: Optional[int]
    death_year: Optional[int]
    birth_month: Optional[int] = None
    birth_day: Optional[int] = None
    highest_office: Optional[str] = None
    office_count: int = 0
    kinship_count: int = 0
    social_count: int = 0
    lifespan: Optional[int] = None


@dataclass
class TrainingRecord:
    """A single training record with BaZi features and outcomes"""
    person_id: int
    features: Dict
    # Outcomes
    lifespan: Optional[int]
    career_peak_age: Optional[int]
    highest_office_rank: Optional[int]
    office_count: int
    social_connections: int
    death_year: Optional[int]


class CBDBPipeline:
    """Pipeline for CBDB data processing"""

    def __init__(self, data_dir: str = "../data"):
        self.data_dir = Path(data_dir)
        self.data_dir.mkdir(parents=True, exist_ok=True)
        self.db_path = self.data_dir / "cbdb_sqlite.db"
        self.calculator = BaZiCalculator()
        self.extractor = FeatureExtractor()

    def download_cbdb(self, force: bool = False) -> bool:
        """Download CBDB SQLite database"""
        if self.db_path.exists() and not force:
            print(f"CBDB database already exists at {self.db_path}")
            return True

        print("Downloading CBDB database...")
        try:
            # Try primary URL
            response = requests.get(CBDB_URL, stream=True, timeout=300)
            response.raise_for_status()

            # Extract from zip
            with zipfile.ZipFile(BytesIO(response.content)) as zf:
                # Find the .db file in the archive
                db_files = [f for f in zf.namelist() if f.endswith('.db')]
                if not db_files:
                    raise ValueError("No .db file found in archive")

                # Extract to data directory
                zf.extract(db_files[0], self.data_dir)
                extracted_path = self.data_dir / db_files[0]
                if extracted_path != self.db_path:
                    extracted_path.rename(self.db_path)

            print(f"Downloaded CBDB to {self.db_path}")
            return True

        except Exception as e:
            print(f"Error downloading CBDB: {e}")
            print("Please download manually from: https://projects.iq.harvard.edu/cbdb/download-cbdb-standalone-database")
            return False

    def connect(self) -> sqlite3.Connection:
        """Connect to CBDB database"""
        if not self.db_path.exists():
            raise FileNotFoundError(f"CBDB database not found at {self.db_path}. Run download_cbdb() first.")
        return sqlite3.connect(self.db_path)

    def get_persons_with_dates(self, limit: Optional[int] = None) -> pd.DataFrame:
        """
        Get all persons with birth/death year data

        Returns DataFrame with columns:
        - c_personid, c_name_chn, c_birthyear, c_deathyear, etc.
        """
        conn = self.connect()

        query = """
        SELECT
            p.c_personid,
            p.c_name_chn,
            p.c_name,
            p.c_birthyear,
            p.c_deathyear,
            p.c_death_age,
            p.c_fl_earliest,
            p.c_fl_latest,
            p.c_female,
            (SELECT COUNT(*) FROM posting_data pd WHERE pd.c_personid = p.c_personid) as office_count,
            (SELECT COUNT(*) FROM kin_data kd WHERE kd.c_personid = p.c_personid) as kin_count,
            (SELECT COUNT(*) FROM assoc_data ad WHERE ad.c_personid = p.c_personid) as social_count
        FROM biog_main p
        WHERE p.c_birthyear IS NOT NULL
          AND p.c_birthyear > 0
          AND p.c_birthyear < 2000
        """

        if limit:
            query += f" LIMIT {limit}"

        df = pd.read_sql_query(query, conn)
        conn.close()

        print(f"Loaded {len(df)} persons with birth year data")
        return df

    def get_career_data(self, person_id: int) -> List[Dict]:
        """Get career/office appointment data for a person"""
        conn = self.connect()

        query = """
        SELECT
            pd.c_firstyear,
            pd.c_lastyear,
            od.c_office_chn,
            od.c_office_rank
        FROM posting_data pd
        LEFT JOIN office_codes od ON pd.c_office_id = od.c_office_id
        WHERE pd.c_personid = ?
        ORDER BY pd.c_firstyear
        """

        cursor = conn.execute(query, (person_id,))
        records = []
        for row in cursor.fetchall():
            records.append({
                'first_year': row[0],
                'last_year': row[1],
                'office_name': row[2],
                'office_rank': row[3]
            })

        conn.close()
        return records

    def calculate_career_peak(self, career_data: List[Dict], birth_year: int) -> Optional[int]:
        """Calculate the age at career peak (highest office)"""
        if not career_data or not birth_year:
            return None

        # Find highest office (lowest rank number = higher position)
        best_rank = float('inf')
        peak_year = None

        for record in career_data:
            rank = record.get('office_rank')
            year = record.get('first_year')
            if rank and year and rank < best_rank:
                best_rank = rank
                peak_year = year

        if peak_year and birth_year:
            return peak_year - birth_year

        return None

    def extract_training_data(self, limit: Optional[int] = None,
                              use_estimated_dates: bool = True) -> List[TrainingRecord]:
        """
        Extract training data from CBDB

        Args:
            limit: Maximum number of records to process
            use_estimated_dates: If True, estimate month/day when not available

        Returns:
            List of TrainingRecord objects
        """
        persons_df = self.get_persons_with_dates(limit)
        records = []

        print("Extracting BaZi features...")
        for _, row in tqdm(persons_df.iterrows(), total=len(persons_df)):
            try:
                birth_year = int(row['c_birthyear'])
                death_year = row['c_deathyear'] if pd.notna(row['c_deathyear']) else None

                # Estimate month/day if not available (use middle of year)
                birth_month = 6 if use_estimated_dates else None
                birth_day = 15 if use_estimated_dates else None

                if birth_month and birth_day:
                    # Calculate BaZi chart (3 pillars - no hour)
                    chart = self.calculator.calculate(birth_year, birth_month, birth_day)
                    features = self.extractor.extract_features(chart)

                    # Calculate outcomes
                    lifespan = None
                    if death_year and birth_year:
                        lifespan = int(death_year) - birth_year
                        if lifespan < 0 or lifespan > 120:
                            lifespan = None

                    # Get career data
                    career_data = self.get_career_data(row['c_personid'])
                    career_peak_age = self.calculate_career_peak(career_data, birth_year)

                    # Highest office rank
                    highest_rank = None
                    if career_data:
                        ranks = [r.get('office_rank') for r in career_data if r.get('office_rank')]
                        if ranks:
                            highest_rank = min(ranks)  # Lower number = higher rank

                    record = TrainingRecord(
                        person_id=row['c_personid'],
                        features=features,
                        lifespan=lifespan,
                        career_peak_age=career_peak_age,
                        highest_office_rank=highest_rank,
                        office_count=row['office_count'] or 0,
                        social_connections=row['social_count'] or 0,
                        death_year=int(death_year) if death_year else None
                    )
                    records.append(record)

            except Exception as e:
                # Skip invalid records
                continue

        print(f"Extracted {len(records)} training records")
        return records

    def to_dataframe(self, records: List[TrainingRecord]) -> pd.DataFrame:
        """Convert training records to DataFrame for ML training"""
        data = []
        for record in records:
            row = record.features.copy()
            row['person_id'] = record.person_id
            row['lifespan'] = record.lifespan
            row['career_peak_age'] = record.career_peak_age
            row['highest_office_rank'] = record.highest_office_rank
            row['office_count'] = record.office_count
            row['social_connections'] = record.social_connections
            row['death_year'] = record.death_year
            data.append(row)

        return pd.DataFrame(data)

    def save_training_data(self, records: List[TrainingRecord],
                           filename: str = "training_data.parquet"):
        """Save training data to parquet file"""
        df = self.to_dataframe(records)
        output_path = self.data_dir / filename
        df.to_parquet(output_path, index=False)
        print(f"Saved training data to {output_path}")
        return output_path

    def load_training_data(self, filename: str = "training_data.parquet") -> pd.DataFrame:
        """Load training data from parquet file"""
        input_path = self.data_dir / filename
        return pd.read_parquet(input_path)

    def get_statistics(self) -> Dict:
        """Get CBDB statistics"""
        conn = self.connect()

        stats = {}

        # Total persons
        cursor = conn.execute("SELECT COUNT(*) FROM biog_main")
        stats['total_persons'] = cursor.fetchone()[0]

        # Persons with birth year
        cursor = conn.execute("SELECT COUNT(*) FROM biog_main WHERE c_birthyear IS NOT NULL AND c_birthyear > 0")
        stats['persons_with_birth_year'] = cursor.fetchone()[0]

        # Persons with death year
        cursor = conn.execute("SELECT COUNT(*) FROM biog_main WHERE c_deathyear IS NOT NULL AND c_deathyear > 0")
        stats['persons_with_death_year'] = cursor.fetchone()[0]

        # Total appointments
        cursor = conn.execute("SELECT COUNT(*) FROM posting_data")
        stats['total_appointments'] = cursor.fetchone()[0]

        # Total kinship records
        cursor = conn.execute("SELECT COUNT(*) FROM kin_data")
        stats['total_kinship_records'] = cursor.fetchone()[0]

        # Total social associations
        cursor = conn.execute("SELECT COUNT(*) FROM assoc_data")
        stats['total_social_records'] = cursor.fetchone()[0]

        conn.close()
        return stats


def main():
    """Main pipeline execution"""
    pipeline = CBDBPipeline()

    # Download CBDB if needed
    if not pipeline.download_cbdb():
        print("Failed to download CBDB. Please download manually.")
        return

    # Print statistics
    print("\nCBDB Statistics:")
    stats = pipeline.get_statistics()
    for key, value in stats.items():
        print(f"  {key}: {value:,}")

    # Extract training data (start with subset for testing)
    print("\nExtracting training data (first 10,000 records for testing)...")
    records = pipeline.extract_training_data(limit=10000)

    # Save to parquet
    output_path = pipeline.save_training_data(records)

    # Load and verify
    df = pipeline.load_training_data()
    print(f"\nTraining data shape: {df.shape}")
    print(f"Columns: {list(df.columns)}")
    print(f"\nSample record:")
    print(df.iloc[0])


if __name__ == "__main__":
    main()
