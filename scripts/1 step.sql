-- ============================================================
/* Section 1 — Membership & Member Overview

This section explores the composition and behaviour of the gym's member base through 6 queries.

	Query 1.1	breaks down active members by membership type, 
				showing how many members each tier holds, 
				what share of the total they represent, 
				and how much monthly revenue each tier generates — 
				giving the gym owner a clear picture of which plans drive the most value.

	Query 1.2	provides a full status breakdown (Active / Inactive / Suspended) with percentage share, 
				allowing management to quickly assess how much of the member base is at risk of being lost.

	Query 1.3	groups active members into age brackets (Under 20 through 60+) 
				and includes the average membership price per group — 
				useful for understanding which demographic the gym attracts and whether pricing aligns with the audience.

	Query 1.4	shows the gender split across all members, 
				which informs decisions about class scheduling, 
				marketing tone, and facility investment.

	Query 1.5	tracks new member registrations month by month, 
				revealing growth trends, seasonal patterns, 
				and whether acquisition is accelerating or slowing over time.

	Query 1.6	measures referral programme effectiveness — 
				what percentage of members joined because an existing member recommended the gym. 
				A high referral rate indicates strong word-of-mouth and low acquisition cost, 
				making the programme worth maintaining or expanding.

Technical notes: 
		
		all queries use window functions (SUM/COUNT OVER()) for percentage calculations without subqueries, 
		CASE WHEN for grouping and labelling, and T-SQL date functions (DATEDIFF, FORMAT, GETDATE) throughout.
*/
-- ============================================================

USE GymAnalysis;
GO

-- ============================================================
--  SECTION 1: MEMBERSHIP & MEMBER OVERVIEW
-- ============================================================

-- 1.1  Member count by membership type + revenue shares 
-- How much members with different memberships produce monthly revenue/average revenue?

SELECT 
	membership_type,
	count(*) AS member_count,
	sum(membership_price_eur)							AS monthly_revenue_eur,
	round(count(*) * 100.00 / SUM(COUNT(*)) OVER(), 2)	AS pct_of_members,
	ROUND(AVG(membership_price_eur), 2)						AS avg_price_eur
FROM dbo.members
WHERE status = 'Active'
GROUP BY membership_type
ORDER BY member_count DESC

-- 1.2  Member status breakdown 
-- How many active/inactive/suspended members are in total/pct?

SELECT status,
count(*) AS total_members,
round(count(*) * 100.0 / sum(count(*)) OVER(), 2) AS pct_members
FROM dbo.members
GROUP BY status
ORDER BY total_members DESC

-- 1.3. Member age distribution
-- How many active gym members are in each age group?

SELECT
	CASE 
		WHEN DATEDIFF(YEAR, date_of_birth, getdate()) < 20 THEN 'Under 20'
		WHEN DATEDIFF(YEAR, date_of_birth, GETDATE()) BETWEEN 20 AND 29 THEN '20-29'
		WHEN DATEDIFF(YEAR, date_of_birth, GETDATE()) BETWEEN 30 AND 39 THEN '30-39'
		WHEN DATEDIFF(YEAR, date_of_birth, GETDATE()) BETWEEN 40 AND 49 THEN '40-49'
		WHEN DATEDIFF(YEAR, date_of_birth, GETDATE()) BETWEEN 50 AND 59 THEN '50-59'
		ELSE '60+'
	END AS age_group,
	COUNT(*) as total_members,
	ROUND(AVG(membership_price_eur),2) AS avg_price
FROM dbo.members
WHERE status = 'Active'
GROUP BY 
	CASE 
		WHEN DATEDIFF(YEAR, date_of_birth, getdate()) < 20 THEN 'Under 20'
		WHEN DATEDIFF(YEAR, date_of_birth, GETDATE()) BETWEEN 20 AND 29 THEN '20-29'
		WHEN DATEDIFF(YEAR, date_of_birth, GETDATE()) BETWEEN 30 AND 29 THEN '30-39'
		WHEN DATEDIFF(YEAR, date_of_birth, GETDATE()) BETWEEN 40 AND 49 THEN '40-49'
		WHEN DATEDIFF(YEAR, date_of_birth, GETDATE()) BETWEEN 50 AND 59 THEN '50-59'
		ELSE '60+'
	END 
ORDER BY age_group 

-- 1.4 Member gender distribution
-- How many gym members are in each sex group?

SELECT 
	CASE
		WHEN gender = 'F' THEN 'Female'
		WHEN gender = 'M' THEN 'Male'
		ELSE 'n/a'
	END AS gender_group,
count(*) AS total_members
FROM dbo.members
group by 
	CASE
		WHEN gender = 'F' THEN 'Female'
		WHEN gender = 'M' THEN 'Male'
		ELSE 'n/a'
	END 
ORDER BY total_members

-- 1.5  New member registrations per month (trend)
-- How many new members are coming to gym by month?

SELECT 
	FORMAT(registration_date, 'yyyy-MM') AS registration_month,
	COUNT(*) AS new_members
FROM dbo.members
GROUP BY 
	FORMAT(registration_date, 'yyyy-MM')
ORDER BY registration_month

-- 1.6  Referral programme effectiveness
-- Is referral programme effective and worth keeping?

SELECT 
	COUNT(*) AS total_members,
	SUM(
		CASE
			WHEN referred_by_member_id IS NOT NULL THEN 1 ELSE 0 END) AS referred_members,
	ROUND(SUM(
		CASE
			WHEN referred_by_member_id IS NOT NULL THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) as referral_rate_pct
FROM dbo.members


