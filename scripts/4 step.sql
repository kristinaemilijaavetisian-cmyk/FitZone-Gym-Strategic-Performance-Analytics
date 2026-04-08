-- ============================================================
/* 
This section evaluates coaching staff from three angles: workload and cost efficiency, 
compliance and licensing, and performance relative to salary — 
giving management the data needed to make informed decisions about contracts, renewals, and hiring.

	Query 4.1	measures each active coach's session load by counting attendance records where they were the assigned coach,
				alongside their average session duration, monthly salary,and cost per supervised session.
				This reveals whether the gym is getting good value from each coach — a highly rated coach with a 
				high session count and low cost per session is the ideal combination. LEFT JOIN ensures 
				coaches with zero sessions still appear, as an active coach on payroll who is never assigned
				represents pure cost with no output.

	Query 4.2	flags each coach's license status into four categories: Expired, Expires Soon (within 3 months),
				Expiry Alert (3–12 months), and OK. Coaches with expired or expiring licenses may be legally
				unable to train clients, creating both liability and operational risk for the gym.
				This query gives management a direct action list prioritised by urgency.

	Query 4.3	ranks individual active coaches by rating and compares each against the overall average using a window function,
				labelling them as above or below average. Combined with salary, this lets the owner identify
				which coaches are underpaid relative to their performance and which contracts may need to be revisited.
				A secondary query groups ratings by specialty, though as noted, results are most meaningful
				when each group contains 3 or more coaches.

	Query 4.4	compares full-time, part-time, and freelance coaches by average salary, total payroll contribution, and average rating.
				This informs future hiring strategy — for example, if freelance coaches deliver competitive ratings at lower cost,
				the gym may benefit from shifting its staffing mix. As noted, conclusions should be treated cautiously
				until each employment group contains a larger sample.

Technical notes:

		Query 4.1 uses LEFT JOIN to preserve zero-session coaches
		and NULLIF to prevent division by zero in cost-per-session.
		
        Query 4.2 uses a staged CASE WHEN with non-overlapping BETWEEN ranges
		— ranges must start where the previous one ends, not from GETDATE(),
		otherwise SQL Server matches the first condition and never reaches later ones.
		
        Query 4.3 uses AVG() OVER() window function to calculate a global average
		inline without a subquery or CTE.
*/
--  SECTION 4: COACH PERFORMANCE & HR
-- ============================================================

-- 4.1  Coach session load
-- How many sessions coaches supervised?
-- What is coaches ratings?
-- What is cost per session?

SELECT 
	c.first_name + ' ' + c.last_name AS coach_name,
    c.specialty,
    c.employment_type,
    c.rating, 
	COUNT(a.attendance_id) AS sessions_supervised,
    ROUND(AVG(CAST(a.duration_minutes AS FLOAT)), 1) as avg_session_min,
	c.monthly_salary_eur,
    ROUND(c.monthly_salary_eur / 
        NULLIF(COUNT(a.attendance_id), 0), 2) AS cost_per_session_eur
FROM dbo.coaches c
LEFT JOIN dbo.attendance a
ON c.coach_id = a.coach_id
WHERE active = 1
GROUP BY c.first_name + ' ' + c.last_name, c.specialty, c.employment_type, c.rating, c.monthly_salary_eur
ORDER BY sessions_supervised DESC;

-- 4.2  License expiry alert (next 12 months)
-- When and whose do licenses expire? 

SELECT 
    coach_id,
    first_name + ' ' + last_name,
    license_type,
        CASE
            WHEN license_expiry < GETDATE() THEN 'Expired'
            WHEN license_expiry BETWEEN GETDATE() AND DATEADD(MONTH, 3, GETDATE()) THEN 'Expires Soon'
            WHEN license_expiry BETWEEN DATEADD(MONTH, 3, GETDATE()) AND DATEADD(MONTH, 12, GETDATE()) THEN 'Expiry Alert'
            ELSE 'OK'
        END AS expiry_alert
FROM dbo.coaches
ORDER BY expiry_alert

-- 4.3  Average coach rating by specialty
-- Which coaches have best ratings according to specialty?

SELECT 
    coach_id,
    first_name + ' ' + last_name AS coach_name,
    specialty,
    employment_type,
    rating,
    monthly_salary_eur,
        -- is this coach above or below average rating?
    CASE
        WHEN rating >= AVG(rating) OVER() THEN 'Above average'
        ELSE 'Below average'
    END AS performance_vs_average
FROM dbo.coaches
WHERE active = 1
ORDER BY rating DESC;

-- Note: Gym owner now can decide, which coaches are overpaid/underpaid, 
-- which he should keep and what contracts he has to revisit for better gym 
-- performance and bigger revenue.

-- Which coach specialty group has best ratings?

SELECT 
    specialty,
    COUNT(*) AS coach_count,
    ROUND(AVG(rating), 2) AS avg_coach_rating,
    ROUND(AVG(monthly_salary_eur), 2) AS avg_salary
FROM dbo.coaches
WHERE active = 1
GROUP BY specialty
ORDER BY avg_coach_rating DESC

-- Note: with 8 active coaches across multiple specialties,
-- most groups contain only 1 coach. The second query becomes more
-- meaningful at scale with 3+ coaches per specialty.
-- In this dataset, individual coach ratings (query above)
-- are more informative than group averages.

-- 4.4  Employment type cost comparison

SELECT 
    employment_type,
    COUNT(*) as coaches,
    ROUND(AVG(monthly_salary_eur), 2) AS avg_salary_eur,
    ROUND(SUM(monthly_salary_eur), 2) AS total_payroll,
    ROUND(AVG(rating), 2) AS avg_rating
FROM dbo.coaches
WHERE active = 1
GROUP BY employment_type
ORDER BY avg_rating DESC

-- Note: Freelance coaches show the lowest cost and competitive ratings in this dataset, 
-- suggesting potential value. However, with only 2 coaches per group, 
-- a larger sample would be needed to confirm this pattern before making hiring decisions.