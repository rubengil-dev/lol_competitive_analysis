# 🎮 League Of Legends Competitive Analytics (2018-2025)

## Overview
The aim of this project is to extract meaningful insights about champion performance, team efficiency, player rankings and game dynamics across 7 years of professional 
League of Legends play.

A relational database was built from [Oracle's Elixir](https://drive.google.com/drive/u/1/folders/1gLSw0RLjBbtaNy0dgnGQDAZOHIgCe-HH) competitive dataset (2018-2025). The original data consisted of separate yearly CSV files, merged via Python into a single staging table and then normalized into a clean dimensional model. It is not uploaded due to its size.

The 2018-2025 window was chosen deliberately: it coincides with the franchising era across major leagues, ensuring more consistent competition structures and team stability.

## Database Model

![ER Diagram](./schema_diagram.JPG)

The model follows a **star schema** with 1 fact table and 7 dimension tables:

| Table | Type | Description |
|-------|------|-------------|
| `player_stats` | Fact | One row per player per game. Core analytics table. |
| `team_stats` | Dimension | Objective and macro stats per team per game. |
| `games_info` | Dimension | Game metadata: date, patch, split, playoffs, duration. |
| `teams` | Dimension | Team registry. |
| `players` | Dimension | Player registry, keyed by Oracle's Elixir player ID. |
| `leagues` | Dimension | League registry with region mapping. |
| `champions` | Dimension | Champion pool with role and subrole classification. |
| `bans` | Dimension | One row per ban, with ban order. |

## Project Structure
```
├── schema.sql          # Database creation, tables, PKs, FKs, constraints
├── load_data.sql       # Data load from raw_data staging table
├── objects.sql         # KDA function & 2 business views
├── eda.sql             # Data quality checks, EDA, business questions
└── schema_diagram.JPG  # ER diagram
```

## How to Run

### Requirements
- MySQL 9.7
- Python 3.x with `Pandas`, `SQLalchemy` y `pyMYSQL`:
- Execute the lane below to install them:

```bash
pip install pandas sqlalchemy pymysql
```


### Steps
1. Download all the yearly CSV files you wanna analyze from [Oracle's Elixir](https://oracleselixir.com/tools/downloads).
2. Place them in a `/data` folder in the same directory as the Python script.
3. Execute schema.sql to create the database and all tables for data import.
4. After `Configuration` (read below), run the Python script to merge CSVs and loads raw_data into MySQL.
5. Execute `load_data.sql`. It may fail due to MYSQL limitations with `INDEX` and `IF EXISTS` interactions. At the beginning of the file, in the `CLEANING PATCH` section, it is explained how to proceed.
6. Execute `objects.sql`.
7. Execute `eda.sql`. If you understand the code, feel free to modify some filter criteria to analyze data your own way.

### Configuration
Before running the Python script:

1. Make sure all your CSVs regardless of their names are in a `/data` folder within the `join_files.py` script.
2. Update the MYSQL connection string with your credentials. This are the actual lines 24-27:
```python
# Push to MySQL as staging table
engine = create_engine("mysql+pymysql://root:@localhost:3306/lol_competitive")
df.to_sql("raw_data", engine, if_exists = "replace", index=False)
print(f"raw_data cargada en MySQL: {len(df)} filas")
```
Change it to:
```python
# Push to MySQL as staging table
engine = create_engine("mysql+pymysql://YOUR_USER:YOUR_PASSWORD@localhost:3306/lol_competitive")
df.to_sql("raw_data", engine, if_exists = "replace", index=False)
print(f"raw_data cargada en MySQL: {len(df)} filas")
```

## Key Insights

All these insights were obtained filtering by major leagues in order to only analyze the best gameplay possible.

- **Major vs Minor leagues**: Major league games last longer, have fewer kills, improved CSing and higher vision scores, which reflects a more structured, macro-oriented playstyle.
- **TOP3 champions by role**: Most of the TOP3 champs are off-role champs which implies that during the patch they were played off-role they were broken.
- **Dragon soul impact**: If we look the whole-time games since dragon soul was released, Hextech is the most porwerful one. However, when we restrict the time lapse to when Hextech and Chemtech dragons were released, to make game amount comparable between souls, the most powerful one is Cloud Soul. Regardless of the time window, Chemtech soul is the worst one eventhough it has 88%+ winrate.
- **Gold advantage by role**: A gold lead at 15 minutes translates to victory most consistently for Mid laners, followed by Junglers, ADC's and lastly by Toplaners. Support were excluded from this analysis due to their low gold income compared with the other 4 roles.
- **Blue side advantage**: Blue side maintains a consistent winrate edge across all years even when restricting games to the same region to avoid region-gap.

## Limitations & Future Work

**Limitations**
- Team rebranding (e.g. SK Telecom T1 → T1) is treated as separate entities due to source data constraints. No persistent team ID was available in the dataset.
- Dragon soul wasn't recorded on original data, so it was inferred using dragon count and type.
- League of Legends is a complex game where this dataset fails to capture the big difference between teams and players. More complex data as mouse movement, camera management, map awarness or team communication would allow a better analysis.

**Future Work**
- Extend and upgrade the player ranking metric to all 5 roles.
- Apply logistic regression to model win probability from early-game stats.
- Analyse the data recomended in previous section to extract game changers to players training.