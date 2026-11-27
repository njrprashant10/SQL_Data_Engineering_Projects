# Warehouse and Data Mart Build

This folder contains a DuckDB star-schema warehouse, a master build script, and analytical marts based on remote job-posting data. The project demonstrates warehouse construction, referential integrity, dimensional modeling, mart design, and incremental snapshot maintenance.

## Data Pipeline

[![Job postings data pipeline](../Resources/job%20postings%20data%20pipeline.png)](../Resources/job%20postings%20data%20pipeline.png)

The scripts load public CSV files from Google Cloud Storage in dependency order:

```text
company_dim.csv + skills_dim.csv
              |
              v
       Warehouse Dimensions
              |
              v
     Job Postings Fact
              |
              v
     Skills Job Bridge
              |
    +---------+---------+
    v         v         v
Flat Mart  Skills Mart  Priority Mart
                              |
                              v
                       Company Hiring Mart
```

## Core Warehouse

[![Core warehouse star schema](../Resources/core%20warehouse%20star%20schema.png)](../Resources/core%20warehouse%20star%20schema.png)

### Script 01 - Create the star schema

[01_create_tables_dw.sql](./01_create_tables_dw.sql) creates:

| Table | Role |
| --- | --- |
| `company_dim` | Company identity and name |
| `skills_dim` | Skill name and skill type |
| `job_postings_fact` | Job-posting attributes and annual/hourly salaries |
| `skills_job_dim` | Composite bridge between postings and skills |

The fact table references `company_dim`, and the bridge references both `skills_dim` and `job_postings_fact`.

### Script 02 - Load and verify

[02_load_schema_dw.sql](./02_load_schema_dw.sql) loads the CSV sources and verifies company, skill, fact, and bridge row counts plus orphaned company, skill, and job keys.

Loading order is significant: dimensions load first, the fact loads second, and the bridge loads last.

## Analytical Marts

### Flat Mart

[![Flat mart](../Resources/flat%20mart.png)](../Resources/flat%20mart.png)

[03_create_flat_mart.sql](./03_create_flat_mart.sql) recreates `flat_mart.job_postings`.

- **Grain:** one row per job posting.
- **Purpose:** consumer-friendly, denormalized job-level analysis.
- **Special feature:** skills are aggregated into an array of DuckDB structs containing skill type and name.
- **Joins:** posting fact, company dimension, job-skill bridge, and skills dimension.

### Skills Demand Mart

[![Skills demand mart](../Resources/skills%20demand%20mart.png)](../Resources/skills%20demand%20mart.png)

[04_create_skills_mart.sql](./04_create_skills_mart.sql) recreates the `skills_mart` schema.

The mart contains `dim_skill`, `dim_date_month`, and `fact_skill_demand_monthly`.

**Fact grain:** one row per skill, month, and short job title.

Measures include total postings, remote postings, health-insurance postings, and postings with no degree mention. These measures are additive and suitable for grouping by month or quarter.

### Priority Roles Mart

[![Priority roles mart](../Resources/priority%20roles%20mart.png)](../Resources/priority%20roles%20mart.png)

[05_create_priority_mart.sql](./05_create_priority_mart.sql) creates role configuration and a snapshot of matching jobs.

[06_update_priority_mart.sql](./06_update_priority_mart.sql) demonstrates incremental synchronization:

- Changes the Data Engineer priority.
- Adds Data Scientist to the priority list.
- Inserts newly matched jobs.
- Updates changed priority values and timestamps.
- Deletes jobs absent from the source.

Matched rows only refresh priority and `updated_at` when the priority changes. Other copied posting fields remain unchanged.

### Company Hiring Mart

[![Company hiring mart schema](../Resources/company%20hiring%20mart%20schema.png)](../Resources/company%20hiring%20mart%20schema.png)

[07_create_company_mart.sql](./07_create_company_mart.sql) creates the `company_mart` schema.

Dimensions include company, short job title, full job title, location, and month. Two bridges model company-location and short-title-full-title relationships.

**Fact grain:** company, short job title, country, and month.

The fact includes posting count, median/minimum/maximum annual salary, remote share, health-insurance share, and no-degree-mention share. Boolean shares treat `TRUE` as `1.0` and `FALSE` or `NULL` as `0.0`.

## Build Instructions

### Build the warehouse and core marts

Run from this folder:

```powershell
duckdb .\dw_marts.duckdb -c ".read build_dw_marts.sql"
```

The master script runs scripts 01 through 06.

### Build the company hiring mart separately

```powershell
duckdb .\dw_marts.duckdb -c ".read 07_create_company_mart.sql"
```

Run this after the core warehouse is loaded.

## Quality and Modeling Practices

- Full schema drops support repeatable rebuilds.
- Primary and foreign keys protect identity and relationships.
- Composite keys represent bridge and aggregate grains.
- Row-count and orphan-key checks detect load problems.
- Monthly dimensions support time-series analysis.
- Boolean flags convert to numeric measures for aggregation.
- Median, minimum, and maximum salaries use the aggregate-grain level.
- The priority snapshot separates configuration from derived job data.

## Conclusions

This folder demonstrates a separation of normalized warehouse storage and purpose-specific marts. The warehouse preserves reusable dimensions and posting facts; each mart changes the grain to match a particular analytical question. This improves query clarity, supports repeatable builds, and keeps relationship and aggregation behavior explicit.
