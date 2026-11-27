# Exploratory Data Analysis

This folder contains three SQL analyses of remote **Data Engineer** postings. Each query joins the job-posting fact to the skills bridge and skills dimension so that counts and salaries are based on explicit skill requirements.

The warehouse and mart database is created by the scripts in [../2_WH_Mart_Build/](../2_WH_Mart_Build/).

[![Top skills in demand](../Resources/top%20skills%20in%20demand.png)](../Resources/top%20skills%20in%20demand.png)

## Analysis Scope

All analyses apply these filters:

- `job_title_short = 'Data Engineer'`
- `job_work_from_home = TRUE`

The results are from the current project data and can change when the public source CSV files are refreshed.

## 01 - Most In-Demand Skills

**SQL file:** [01_top_demanded_skills.sql](./01_top_demanded_skills.sql)

This query counts job-skill relationships and returns the ten highest-demand skills for remote Data Engineer postings.

| Rank | Skill | Demand count |
| ---: | --- | ---: |
| 1 | SQL | 29,221 |
| 2 | Python | 28,776 |
| 3 | AWS | 17,823 |
| 4 | Azure | 14,143 |
| 5 | Spark | 12,799 |
| 6 | Airflow | 9,996 |
| 7 | Snowflake | 8,639 |
| 8 | Databricks | 8,183 |
| 9 | Java | 7,267 |
| 10 | GCP | 6,446 |

The counts are not mutually exclusive because one posting can require multiple skills.

**Key insight:** SQL and Python form the strongest general foundation. AWS, Azure, Spark, and Airflow identify cloud and data-platform skills commonly associated with remote engineering roles.

## 02 - Highest Median-Paying Skills

**SQL file:** [02_top_paying_skills.sql](./02_top_paying_skills.sql)

This query calculates median annual salary per skill and requires at least 100 matching postings. Median salary is more resistant to extreme salaries than an average.

| Skill | Median annual salary | Skill count |
| --- | ---: | ---: |
| Rust | $210,000 | 232 |
| Golang | $184,000 | 912 |
| Terraform | $184,000 | 3,248 |
| Spring | $175,500 | 364 |
| Neo4j | $170,000 | 277 |

**Key insight:** The highest-paid skills include infrastructure, backend, and specialization technologies. Some have less total demand than SQL or Python, so salary should be considered alongside market frequency.

## 03 - Skills Balancing Demand and Salary

**SQL file:** [03_optimal_skills.sql](./03_optimal_skills.sql)

This query restricts analysis to salary-reported postings and skills with at least 100 matching postings. It combines median salary with the natural logarithm of demand:

```text
optimal_score = LN(demand_count) * median_salary / 1,000,000
```

| Skill | Median salary | Demand count | Optimal score |
| --- | ---: | ---: | ---: |
| Terraform | $184,000 | 193 | 0.97 |
| Python | $135,000 | 1,133 | 0.95 |
| AWS | $137,320 | 783 | 0.91 |
| SQL | $130,000 | 1,128 | 0.91 |
| Airflow | $150,000 | 386 | 0.89 |

**Key insight:** This view highlights skills that combine hiring volume with compensation better than a raw salary ranking. It is useful for prioritizing foundational learning while identifying higher-value specialization areas.

## Conclusions

1. SQL and Python are the strongest baseline skills for a remote Data Engineering career.
2. Cloud and orchestration skills such as AWS, Azure, Airflow, Spark, Snowflake, and Databricks are highly relevant.
3. Salary leaders such as Rust, Golang, and Terraform should complement rather than replace the foundational skill set.
4. Terraform and Python offer a strong demand-and-salary combination in the current data.
5. Counts, medians, and scores describe a specific dataset snapshot; source refreshes can change the rankings.

## Run the Analyses

From the project root:

```powershell
Push-Location .\1_EDA
duckdb ..\2_WH_Mart_Build\dw_marts.duckdb -c ".read 01_top_demanded_skills.sql"
duckdb ..\2_WH_Mart_Build\dw_marts.duckdb -c ".read 02_top_paying_skills.sql"
duckdb ..\2_WH_Mart_Build\dw_marts.duckdb -c ".read 03_optimal_skills.sql"
Pop-Location
```
