-- ============================================================
/*
This section analyses the performance of the gym's group class schedule, identifying which classes attract members consistently, 
which are underperforming financially, and how class availability is distributed across the week.

	Query 5.1	aggregates active classes by name, showing how many times each class appears in the schedule,
				its average capacity, average enrollment, and overall fill rate percentage. This gives the owner 
				a ranked view of which classes are genuinely popular and which are consistently underused,
				informing decisions about which classes to expand, repromote, or remove from the schedule.

	Query 5.2	drills into underperforming classes specifically — those with a fill rate below 50% —
				and calculates the revenue lost per session due to empty seats. Results are ordered 
				by lost revenue descending, so the most financially damaging classes appear first
				and become the immediate priority for action. For each class the owner can decide whether to
				reschedule to a better time slot, run a promotion to fill seats, or cancel and redeploy the coach
				to higher-value personal training sessions.

	Query 5.3	shows how many active classes and total capacity spots exist for each day of the week.
				Combined with the attendance data from Section 2, this reveals whether class availability aligns
				with actual member visit patterns — for example, if Saturday has the most visitors
				but the fewest scheduled classes, that is a clear gap and growth opportunity.

Technical notes:

		Query 5.1 uses CAST(column AS FLOAT) before AVG to prevent integer division truncating decimal results.
		
		Query 5.2 uses CONVERT(VARCHAR(5), start_time, 108) to display time in HH:MM format without seconds.
		
		Query 5.3 uses a CASE WHEN inside ORDER BY to sort days Monday through Sunday chronologically
		rather than alphabetically — a common pattern whenever natural language values need a custom sort order.
*/

-- ============================================================
--  SECTION 5: GROUP CLASSES
-- ============================================================

-- 5.1  Class fill rate

SELECT 
	class_name,
	COUNT(*)		AS schedule_slots, -- number of times this class appears in the schedule
	ROUND(AVG(CAST(capacity AS FLOAT)), 0)		AS avg_capacity,
	ROUND(AVG(CAST(enrolled_count AS FLOAT)), 0)  AS avg_enrolled,
	ROUND(AVG(CAST(enrolled_count AS FLOAT)  * 100.0 / capacity), 1) AS fill_rate_pct
FROM dbo.group_classes
WHERE active = 1
GROUP BY class_name
ORDER BY fill_rate_pct DESC

-- 5.2  Under-performing classes (fill rate below 50%)
-- Which classes do underperform and loose the biggest revenue per session?

SELECT
    class_id,
    class_name,
    day_of_week,
    CONVERT(VARCHAR(5), start_time, 108)    AS start_time,
    capacity,
    enrolled_count,
    ROUND(CAST(enrolled_count AS FLOAT) * 100 / capacity, 1)   AS fill_rate_pct,
    ROUND((capacity - enrolled_count) * price_per_session_eur, 2) AS lost_revenue_per_session_eur
FROM group_classes
WHERE active = 1
  AND CAST(enrolled_count AS FLOAT) / capacity < 0.5
ORDER BY lost_revenue_per_session_eur DESC;

-- 5.3  Classes per day of week

SELECT 
    day_of_week,
    COUNT(*)            AS active_classes,
    SUM(capacity)       AS total_spots
FROM dbo.group_classes
WHERE active = 1
GROUP BY day_of_week
ORDER BY 
    CASE day_of_week
        WHEN 'Monday'       THEN 1      WHEN 'Tuesday'  THEN 2 
        WHEN 'Wednesday'    THEN 3      WHEN 'Thursday' THEN 4
        WHEN 'Friday'       THEN 5      WHEN 'Saturday' THEN 6
        WHEN 'Sunday'       THEN 7
        END;

