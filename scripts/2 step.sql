-- ============================================================
/* 
Section 2 — Attendance & Engagement

This section analyses how, when, and how often members use the gym, giving management a data-driven view of engagement patterns 
and early warning signals of member loss.

	Query 2.1	tracks total visits and unique visitors per month,
				revealing seasonal attendance trends and whether
				the gym is retaining regular visitors or relying
				on one-time traffic each month.

	Query 2.2	distributes all visits by hour of the day,
				identifying peak and quiet periods —
				useful for staffing decisions, class scheduling,
				and equipment maintenance planning.

	Query 2.3	counts visits by day of the week and includes
				average session duration per day,
				showing not just which day is busiest but whether
				members engage more deeply on certain days.
				Results are ordered Monday to Sunday for natural readability.

	Query 2.4	ranks workout types by total sessions and percentage share,
				helping management understand which activities drive attendance
				and where to invest in coaching or equipment.

	Query 2.5	identifies the top 10 most active members by visit count,
				including their average session duration —
				these members are ideal candidates for loyalty rewards
				or referral programme incentives.

	Query 2.6	flags active members who have not visited in the last 60 days,
				ordered by most overdue first.
				Members who stop visiting are statistically the most likely
				to cancel soon — this list gives the gym a direct action target
				for re-engagement outreach before revenue is lost.
				NULL last visit (members who have never visited) are included,
				as they represent the highest churn risk of all.

Technical notes:

		all percentage calculations use a subquery in the SELECT clause (query 2.4),
		LEFT JOIN is used throughout to preserve members with no attendance records,
		CAST(duration_minutes AS FLOAT) ensures accurate decimal averages,
		and HAVING filters post-aggregation results that WHERE cannot handle.
*/
-- ============================================================

-- ============================================================
--  SECTION 2: ATTENDANCE & ENGAGEMENT
-- ============================================================

-- 2.1  Total visits per month
-- How many people attend gym per month?

SELECT 
	FORMAT(check_in_time,'yyyy-MM') AS visit_month,
	COUNT(*) AS total_visits,
	COUNT(DISTINCT member_id) AS unique_visits
FROM dbo.attendance
GROUP BY FORMAT(check_in_time, 'yyyy-MM')
ORDER BY visit_month


-- 2.2  Peak hours (visit distribution by hour of day)
-- How many unique visits happen during each hour?

SELECT 
	DATEPART(HOUR, check_in_time) AS visit_hour,
	COUNT(*) AS total_visits
FROM dbo.attendance
GROUP BY DATEPART(HOUR, check_in_time)
ORDER BY visit_hour

-- 2.3  Busiest day of the week
-- In what day of the week there are the most visitors?

SELECT
	DATENAME(WEEKDAY, check_in_time) AS week_day,
	COUNT(*) AS total_visits,
	ROUND(AVG(CAST(duration_minutes AS FLOAT)), 2) AS avg_duration_min
FROM dbo.attendance
GROUP BY
	DATENAME(WEEKDAY, check_in_time)
ORDER BY
	CASE	
		DATENAME(WEEKDAY, check_in_time)
				WHEN 'Monday'		THEN 1
				WHEN 'Tuesday'		THEN 2
				WHEN 'Wednesday'	THEN 3
				WHEN 'Thursday'		THEN 4
				WHEN 'Friday'		THEN 5
				WHEN 'Saturday'		THEN 6
				WHEN 'Sunday'		THEN 7
	END


	-- 2.4  Most popular workout types
	-- What workout types are the most popular and what is their percentange share?

SELECT
	workout_type,
	COUNT(*) AS sessions,
	ROUND(AVG(CAST(duration_minutes AS FLOAT)), 1) AS avg_duration_min,
	ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM dbo.attendance), 2) AS pct_share
FROM dbo.attendance
GROUP BY workout_type
ORDER BY sessions DESC

-- 2.5  Top 10 most active members

SELECT top 10
	m.first_name + ' ' + m.last_name,
	count(a.attendance_id) AS active_visits,
	ROUND(AVG(CAST(a.duration_minutes AS FLOAT)), 1) AS avg_duration_min
FROM dbo.attendance a
LEFT JOIN dbo.members m
ON a.member_id = m.member_id
GROUP BY m.first_name + ' ' + m.last_name
ORDER BY active_visits DESC

-- 2.6  Churn risk: active members with no visit in last 60 days
-- Which 50 active members did not visit in last 60 days and when was their last visit?

SELECT TOP 50
	m.member_id,
	m.first_name + ' ' + m.last_name AS member_name,
	m.membership_type,
	m.email,
	MAX(a.check_in_time) AS last_visit
FROM dbo.members m
LEFT JOIN dbo.attendance a
ON m.member_id = a.member_id
WHERE m.status = 'Active'
GROUP BY
	m.member_id,
	m.first_name  + ' ' + m.last_name,
	m.membership_type,
	m.email
HAVING 
	MAX(a.check_in_time) < DATEADD(DAY, -60, GETDATE()) 
	OR
	MAX(a.check_in_time) IS NULL
ORDER BY last_visit ASC