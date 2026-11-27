-- Step 4: Mart - Create skills demand mart (dimensional mart)

-- This mart focuses on skills demand over time with clean additive measures

-- Drop existing mart schema if it exists (for idempotency)

DROP SCHEMA IF EXISTS skills_mart CASCADE;

-- Step 1: Create the mart schema
CREATE SCHEMA skills_mart;

SELECT '=== Loading Skill Dim for Skills Mart===' AS info;

-- Step 2: Create dimension tables

-- 1. Skills dimension
CREATE OR REPLACE TABLE skills_mart.dim_skill (
    skill_id INTEGER PRIMARY KEY,
    skills VARCHAR,
    type VARCHAR
);


INSERT INTO skills_mart.dim_skill (skill_id, skills, type)
SELECT
    skill_id,
    skill,
    type
FROM skills_dim;

SELECT '=== Loading Skill Fact for Skills Mart===' AS info;

-- 2. Month-level date dimension (enhanced with quarter and other attributes)
CREATE OR REPLACE TABLE skills_mart.dim_date_month (
    month_start_date DATE PRIMARY KEY,
    year INTEGER,
    month INTEGER,
    quarter INTEGER,
    quarter_name VARCHAR,
    year_quarter VARCHAR
);


INSERT INTO skills_mart.dim_date_month (
    month_start_date,
    year,
    month,
    quarter,
    quarter_name,
    year_quarter
)

SELECT DISTINCT 
    DATE_TRUNC('month', job_posted_date) AS month_start_date,
    EXTRACT(YEAR FROM job_posted_date) AS year,
    EXTRACT(MONTH FROM job_posted_date) AS month,
    EXTRACT(QUARTER FROM job_posted_date) AS quarter,
  -- Quarter name
    'Q-' || EXTRACT(QUARTER FROM job_posted_date) ::VARCHAR AS quarter_name,
     -- Year-Quarter combination for easy filtering
     EXTRACT(YEAR FROM job_posted_date)::VARCHAR || '-Q' ||
     EXTRACT(QUARTER FROM job_posted_date) ::VARCHAR AS year_quarter

FROM job_postings_fact
WHERE job_posted_date IS NOT NULL
ORDER BY month_start_date;

-- Step 3: Create fact table - fact_skill_demand_monthly
SELECT '=== Loading Skill Demand Monthly for Skills Mart===' AS info;
CREATE TABLE skills_mart.fact_skill_demand_monthly (
    skill_id INTEGER,
    month_start_date DATE,
    job_title_short VARCHAR,
    postings_count INTEGER,
    remote_postings_count INTEGER,
    health_insurance_postings_count INTEGER,
    no_degree_mention_count INTEGER,
      PRIMARY KEY (skill_id, month_start_date, job_title_short),
    FOREIGN KEY (skill_id) REFERENCES skills_mart.dim_skill(skill_id),
    FOREIGN KEY (month_start_date) REFERENCES skills_mart.dim_date_month(month_start_date)
);
INSERT INTO skills_mart.fact_skill_demand_monthly (
    skill_id,
    month_start_date,
    job_title_short,
    postings_count,
    remote_postings_count,
    health_insurance_postings_count,
    no_degree_mention_count
)


WITH job_postings_prep AS(
SELECT
    sjd.skill_id,
    DATE_TRUNC('month', jpf.job_posted_date) AS month_start_date,
    jpf.job_title_short,

    CASE WHEN jpf.job_work_from_home=TRUE THEN 1 ELSE 0 END AS is_remote,
    CASE WHEN jpf.job_health_insurance = TRUE THEN 1 ELSE 0 END AS has_health_insurance,
    CASE WHEN jpf.job_no_degree_mention = TRUE THEN 1 ELSE 0 END AS no_degree_mention

FROM job_postings_fact as jpf
INNER JOIN 
    skills_job_dim as sjd
    ON sjd.job_id = jpf.job_id
)
SELECT 
    skill_id,
    month_start_date,
    job_title_short,

    COUNT(*) AS postings_count,
    
    SUM(is_remote) AS remote_postings_count,
    SUM(has_health_insurance) AS health_insurance_postings_count,
    SUM(no_degree_mention) AS no_degree_mention_count

FROM job_postings_prep
GROUP BY ALL
ORDER BY skill_id, month_start_date, job_title_short;

-- Verify mart was created
SELECT 'Skill Dimension' AS table_name, COUNT(*) as record_count FROM skills_mart.dim_skill
UNION ALL
SELECT 'Date Month Dimension', COUNT(*) FROM skills_mart.dim_date_month
UNION ALL
SELECT 'Skill Demand Fact', COUNT(*) FROM skills_mart.fact_skill_demand_monthly;

-- Show sample data from each table
SELECT '=== Skill Dimension Sample ===' AS info;
SELECT * FROM skills_mart.dim_skill LIMIT 10;

SELECT '=== Date Month Dimension Sample ===' AS info;
SELECT * FROM skills_mart.dim_date_month ORDER BY month_start_date DESC LIMIT 10;

SELECT '=== Skill Demand Fact Sample ===' AS info;
SELECT * FROM skills_mart.fact_skill_demand_monthly LIMIT 10;
