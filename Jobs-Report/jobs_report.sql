-- Create company_dim table with primary key
CREATE TABLE public.company_dim
(
    company_id INT PRIMARY KEY,
    name TEXT,
    link TEXT,
    link_google TEXT,
    thumbnail TEXT
);

-- Create skills_dim table with primary key
CREATE TABLE public.skills_dim
(
    skill_id INT PRIMARY KEY,
    skills TEXT,
    type TEXT
);

-- Create job_postings_fact table with primary key
CREATE TABLE public.job_postings_fact
(
    job_id INT PRIMARY KEY,
    company_id INT,
    job_title_short VARCHAR(255),
    job_title TEXT,
    job_location TEXT,
    job_via TEXT,
    job_schedule_type TEXT,
    job_work_from_home BOOLEAN,
    search_location TEXT,
    job_posted_date TIMESTAMP,
    job_no_degree_mention BOOLEAN,
    job_health_insurance BOOLEAN,
    job_country TEXT,
    salary_rate TEXT,
    salary_year_avg NUMERIC,
    salary_hour_avg NUMERIC,
    FOREIGN KEY (company_id) REFERENCES public.company_dim (company_id)
);

-- Create skills_job_dim table with a composite primary key and foreign keys
CREATE TABLE public.skills_job_dim
(
    job_id INT,
    skill_id INT,
    PRIMARY KEY (job_id, skill_id),
    FOREIGN KEY (job_id) REFERENCES public.job_postings_fact (job_id),
    FOREIGN KEY (skill_id) REFERENCES public.skills_dim (skill_id)
);

-- Set ownership of the tables to the postgres user
ALTER TABLE public.company_dim OWNER to postgres;
ALTER TABLE public.skills_dim OWNER to postgres;
ALTER TABLE public.job_postings_fact OWNER to postgres;
ALTER TABLE public.skills_job_dim OWNER to postgres;

-- Create indexes on foreign key columns for better performance
CREATE INDEX idx_company_id ON public.job_postings_fact (company_id);
CREATE INDEX idx_skill_id ON public.skills_job_dim (skill_id);
CREATE INDEX idx_job_id ON public.skills_job_dim (job_id); 


-- Import File

COPY company_dim FROM 'C:\Temp/company_dim.csv'
WITH(FORMAT CSV, HEADER, DELIMITER ',');

COPY job_postings_fact FROM 'C:\Temp/job_postings_fact.csv'
WITH(FORMAT CSV, HEADER, DELIMITER ',');

COPY skills_dim FROM 'C:\Temp/skills_dim.csv'
WITH(FORMAT CSV, HEADER, DELIMITER ',');

COPY skills_job_dim FROM 'C:\Temp/skills_job_dim.csv'
WITH(FORMAT CSV, HEADER, DELIMITER ',');


-- Test all table 
SELECT * 
FROM company_dim;

SELECT * 
FROM job_postings_fact;

SELECT * 
FROM skills_dim;

SELECT * 
FROM skills_job_dim;




-- Project 1
-- Top 10 paying Company for remote job
SELECT 
    d.name,
    f.job_schedule_type,
    f.job_posted_date::DATE,
    f.salary_year_avg AS totals
FROM 
    job_postings_fact AS f
INNER JOIN 
    company_dim AS d
USING (company_id)
WHERE 
    job_title_short = 'Data Analyst'
AND
    salary_year_avg IS NOT NULL
AND 
    job_work_from_home = True
ORDER BY 
    totals DESC
LIMIT 10;

-- Project 2
-- Skills Demand only for remote location
WITH skills_demand AS (
    SELECT 
        f.job_id,
        d.name,
        f.job_schedule_type,
        f.job_posted_date::DATE,
        f.salary_year_avg AS totals
    FROM 
        job_postings_fact AS f
    INNER JOIN 
        company_dim AS d
    USING (company_id)
    WHERE 
        job_title_short = 'Data Analyst'
    AND
        salary_year_avg IS NOT NULL
    AND 
        job_work_from_home = True
)
SELECT
    d2.skills,
    COUNT(f.job_id) as total
FROM skills_demand AS f
INNER JOIN 
    skills_job_dim AS d
USING (job_id)
INNER JOIN 
    skills_dim AS d2 ON d.skill_id = d2.skill_id
GROUP BY
    d2.skills
ORDER BY 
    total DESC
LIMIT 10;

-- Project 3
-- Skills demand for all data analyst location
WITH skills_demand AS (
    SELECT 
        f.job_id,
        d.name,
        f.job_schedule_type,
        f.job_posted_date::DATE,
        f.salary_year_avg AS totals
    FROM 
        job_postings_fact AS f
    INNER JOIN 
        company_dim AS d
    USING (company_id)
    WHERE 
        job_title_short = 'Data Analyst'
)
SELECT
    d2.skills,
    COUNT(f.job_id) as total
FROM skills_demand AS f
JOIN 
    skills_job_dim AS d
USING (job_id)
INNER JOIN 
    skills_dim AS d2 ON d.skill_id = d2.skill_id
GROUP BY
    d2.skills
ORDER BY 
    total DESC
LIMIT 10;

-- Project 4
-- Top salary for Remote data analyst By skill
SELECT
    d2.skills,
    ROUND(
        AVG(f.salary_year_avg)::NUMERIC, 0
    ) AS salary_avergae
FROM
    job_postings_fact AS f
INNER JOIN 
    skills_job_dim AS d
USING (job_id)
INNER JOIN
    skills_dim AS d2 ON d.skill_id = d2.skill_id
WHERE
    job_title_short = 'Data Analyst'
AND
    salary_year_avg IS NOT NULL
AND 
    job_work_from_home = True
GROUP BY 
    d2.skills
ORDER BY
    salary_avergae DESC
LIMIT 25;


-- Project 5
-- High demand & high salary skill for remote
WITH skills_demand AS (
    SELECT
        d2.skill_id,
        d2.skills,
        COUNT(f.job_id) AS total
    FROM
        job_postings_fact AS f
    INNER JOIN 
        skills_job_dim AS d
    USING (job_id) 
    INNER JOIN 
        skills_dim AS d2 ON d.skill_id = d2.skill_id
    WHERE 
        job_title_short = 'Data Analyst'
    AND 
        job_work_from_home = True
    AND 
        salary_year_avg IS NOT NULL
    GROUP BY 
        d2.skill_id, d2.skills
),
salary_avergae AS (
    SELECT
        d2.skill_id,
        d2.skills,
        ROUND(
        AVG(f.salary_year_avg)::NUMERIC, 0
        ) AS salary_avergae
    FROM
        job_postings_fact AS f
    INNER JOIN 
        skills_job_dim AS d
    USING (job_id)
    INNER JOIN
        skills_dim AS d2 ON d.skill_id = d2.skill_id
    WHERE
        job_title_short = 'Data Analyst'
    AND
        job_work_from_home = True
     AND
        salary_year_avg IS NOT NULL
    GROUP BY 
        d2.skill_id, d2.skills
)
SELECT
    f.skills,
    SUM(f.total) AS demand,
    ROUND(
        AVG(d.salary_avergae)::NUMERIC, 0
    ) AS salary 
FROM 
    skills_demand AS f
INNER JOIN 
    salary_avergae AS d
USING 
    (skill_id)
GROUP BY 
    f.skills
ORDER BY
    demand DESC
LIMIT 10;