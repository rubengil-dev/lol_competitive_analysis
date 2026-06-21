# Imports
from pathlib import Path
import pandas as pd
from sqlalchemy import create_engine

# Path for DATA
data_path = Path(__file__).parent / "data"

# Get all CSV in DATA
files = list(data_path.glob("*.csv"))
print(f"Found {len(files)} files: {[f.name for f in files]}")

# CSV merge
df = pd.concat([pd.read_csv(f, low_memory=False) for f in files], ignore_index=True)

# Final check
print(f"Total rows: {len(df)}")
print(f"Columns: {list(df.columns)}")

# Save new csv
df.to_csv(data_path / "lol_alldata.csv", index=False)
print(f"Saved to {data_path / 'lol_alldata.csv'}")

# Push to MySQL as staging table
engine = create_engine("mysql+pymysql://root:@localhost:3306/lol_competitive")
df.to_sql("raw_data", engine, if_exists = "replace", index=False)
print(f"raw_data cargada en MySQL: {len(df)} filas")