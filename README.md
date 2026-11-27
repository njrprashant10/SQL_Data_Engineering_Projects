# SQL Data Engineering Projects

An end-to-end SQL portfolio project for analyzing remote Data Engineer job postings and transforming source data into a DuckDB dimensional warehouse and analytical data marts.

## Project overview

This repository contains two related projects:

1. **[Exploratory analysis](./1_EDA/README.md)** - identifies in-demand skills, high-paying skills, and skills that balance demand with salary.
2. **[Warehouse and marts](./2_WH_Mart_Build/README.md)** - loads a star-schema warehouse and builds flat, skills, priority, and company-hiring analytical marts.

The warehouse fact grain is one row per job posting. The skills mart grain is skill, month, and short job title. The company mart grain is company, short job title, country, and month.

## Project architecture

[![Job postings data pipeline](./Resources/job%20postings%20data%20pipeline.png)](./Resources/job%20postings%20data%20pipeline.png)

```text
Public CSV sources
        |
        v
Company and skills dimensions
        |
        v
Job postings fact
        |
        v
Job-skill bridge
        |
        +--> Flat mart
        +--> Skills demand mart
        +--> Priority roles mart
        +--> Company hiring mart
```

## Repository structure

```text
SQL_Data_Engineering_Projects/
├── 1_EDA/
│   ├── 01_top_demanded_skills.sql
│   ├── 02_top_paying_skills.sql
│   ├── 03_optimal_skills.sql
│   └── README.md
├── 2_WH_Mart_Build/
│   ├── 01_create_tables_dw.sql
│   ├── 02_load_schema_dw.sql
│   ├── 03_create_flat_mart.sql
│   ├── 04_create_skills_mart.sql
│   ├── 05_create_priority_mart.sql
│   ├── 06_update_priority_mart.sql
│   ├── 07_create_company_mart.sql
│   ├── build_dw_marts.sql
│   ├── dw_marts.duckdb
│   └── README.md
├── Resources/
└── README.md
```

## EDA insights

[![Top skills in demand](./Resources/top%20skills%20in%20demand.png)](./Resources/top%20skills%20in%20demand.png)

All three analyses focus on remote postings with `job_title_short = 'Data Engineer'`.

| Analysis | SQL file | Result |
| --- | --- | --- |
| Most in demand | [01_top_demanded_skills.sql](./1_EDA/01_top_demanded_skills.sql) | SQL (29,221), Python (28,776), and AWS (17,823) lead demand |
| Highest median salary | [02_top_paying_skills.sql](./1_EDA/02_top_paying_skills.sql) | Rust ($210,000) ranks highest among skills with at least 100 postings |
| Demand and salary balance | [03_optimal_skills.sql](./1_EDA/03_optimal_skills.sql) | Terraform, Python, AWS, and SQL rank highly |

The optimal-skills score is:

```text
optimal_score = LN(demand_count) * median_salary / 1,000,000
```

The natural-log demand term reduces the dominance of very frequent skills, while median salary captures compensation. Full query details and rankings are documented in the [EDA README](./1_EDA/README.md).

## Data warehouse

[![Core warehouse star schema](./Resources/core%20warehouse%20star%20schema.png)](./Resources/core%20warehouse%20star%20schema.png)

| Table | Role | Grain or key |
| --- | --- | --- |
| `job_postings_fact` | Posting attributes, work arrangement, and salary fields | One row per `job_id` |
| `company_dim` | Company names | `company_id` |
| `skills_dim` | Skill names and types | `skill_id` |
| `skills_job_dim` | Job-to-skill relationship | Composite key: `skill_id`, `job_id` |

The build loads dimensions before facts, loads the fact before the bridge, and checks for orphaned company, skill, and job keys. Full implementation details are in the [warehouse and mart README](./2_WH_Mart_Build/README.md).

## Data marts

### Flat mart

[![Flat mart](./Resources/flat%20mart.png)](./Resources/flat%20mart.png)

`flat_mart.job_postings` keeps one row per job posting and aggregates associated skills into an array of `{type, name}` structures.

**Script:** [03_create_flat_mart.sql](./2_WH_Mart_Build/03_create_flat_mart.sql)

### Skills demand mart

[![Skills demand mart](./Resources/skills%20demand%20mart.png)](./Resources/skills%20demand%20mart.png)

`skills_mart.fact_skill_demand_monthly` contains monthly demand measures for every skill and short job title. It supports additive counts and date-dimension filtering.

**Script:** [04_create_skills_mart.sql](./2_WH_Mart_Build/04_create_skills_mart.sql)

### Priority roles mart

[![Priority roles mart](./Resources/priority%20roles%20mart.png)](./Resources/priority%20roles%20mart.png)

The priority mart maintains role priorities and a job snapshot. The update demonstrates `MERGE` inserts, priority updates, and deletions for jobs absent from the refreshed source.

**Scripts:** [05_create_priority_mart.sql](./2_WH_Mart_Build/05_create_priority_mart.sql) and [06_update_priority_mart.sql](./2_WH_Mart_Build/06_update_priority_mart.sql)

### Company hiring mart

[![Company hiring mart schema](./Resources/company%20hiring%20mart%20schema.png)](./Resources/company%20hiring%20mart%20schema.png)

The company mart aggregates hiring by company, short title, country, and month. Measures include posting count, salary statistics, remote share, health-insurance share, and no-degree-mention share.

**Script:** [07_create_company_mart.sql](./2_WH_Mart_Build/07_create_company_mart.sql)

## How to run

### Requirements

- DuckDB CLI
- Internet access for the public Google Cloud Storage CSV sources

### Build warehouse and core marts

```powershell
Push-Location .\2_WH_Mart_Build
duckdb .\dw_marts.duckdb -c ".read build_dw_marts.sql"
Pop-Location
```

### Build company hiring mart

```powershell
Push-Location .\2_WH_Mart_Build
duckdb .\dw_marts.duckdb -c ".read 07_create_company_mart.sql"
Pop-Location
```

### Run an EDA query

```powershell
Push-Location .\1_EDA
duckdb ..\2_WH_Mart_Build\dw_marts.duckdb -c ".read 01_top_demanded_skills.sql"
Pop-Location
```

Replace `01_top_demanded_skills.sql` with `02_top_paying_skills.sql` or `03_optimal_skills.sql`.

## SQL techniques demonstrated

- Star-schema design and fact/bridge modeling
- Primary, foreign, and composite keys
- Remote CSV ingestion
- CTEs and grouped aggregations
- Median, minimum, maximum, and percentage-share calculations
- Monthly and quarterly date dimensions
- Boolean-to-numeric transformations
- Nested arrays of structured values
- Idempotent schema rebuilds
- `MERGE` for incremental snapshot synchronization

## Key takeaways

1. SQL and Python are the most dependable baseline skills for the remote Data Engineer market.
2. AWS, Azure, Spark, Airflow, Snowflake, and Databricks are highly relevant platform and pipeline skills.
3. Specialized skills can command higher salaries, but demand and salary should be considered together.
4. A clear fact grain and bridge grain make warehouse relationships and aggregations easier to validate.
5. Analytical marts should be modeled for the consumer question rather than as copies of the warehouse fact.

## Conclusions

The project demonstrates a complete SQL analytical workflow: source loading, warehouse modeling, integrity validation, mart creation, and insight generation. In the current data, a strong Data Engineering foundation combines SQL and Python with cloud and orchestration technologies. Infrastructure skills such as Terraform and specialized languages such as Rust can increase career flexibility or compensation. The optimal-skills view provides the most practical learning priority because it balances market demand with salary rather than selecting solely on one dimension.
