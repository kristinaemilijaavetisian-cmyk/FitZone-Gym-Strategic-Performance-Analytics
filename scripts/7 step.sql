-- ============================================================
/*
Section 7 — Growth & Opportunity Insights

This section shifts focus from describing the current state of the business to identifying forward-looking opportunities — 
where the gym is growing, who can be converted to higher-value plans, and whether pricing is translating into actual collected revenue.

	Query 7.1	tracks new member registrations year over year, calculating the absolute difference and percentage growth
				compared to the previous year. A consistently positive yoy_growth_pct confirms the gym is successfully attracting new members.
				A declining trend is an early warning signal that marketing or pricing strategy needs to be revisited
				before it impacts total membership numbers. NULL in the first year row is expected — there is no previous year to compare against.

	Query 7.2	identifies active members on low-tier plans (Basic, Student, Day Pass) who have visited the gym 20 or 
				more times in the last 12 months. These are high-engagement, low-revenue members — the most likely 
				candidates to accept an upgrade offer since they clearly value the gym already. The potential_upgrade_gain_eur 
				column shows exactly how much additional monthly revenue each conversion would generate,
				turning the list into a prioritised sales action plan.

	Query 7.3	shows the gender split of active members with percentage share. This informs decisions about class scheduling,
				marketing tone, equipment investment, and whether the gym is reaching its target demographic. A significant 
				imbalance may suggest untapped growth potential in the underrepresented group.

	Query 7.4	compares two revenue figures side by side: the average membership price (what members should pay)
				and actual revenue per active member (what the gym collects). The difference column reveals the gap between
				expected and real income — a negative difference indicates that failed payments, refunds, or discounts are reducing revenue
				below what the pricing structure would suggest, while a positive difference suggests members
				are spending beyond their base plan through additional classes or day passes.

Technical notes:

		Query 7.1 uses the LAG window function to access the previous row's value without a self-join,
			enabling year-over-year comparison in a single query. NULLIF prevents division by zero in yoy_growth_pct
			for the first year row where LAG returns NULL.

		Query 7.2 uses HAVING to filter after aggregation — visit count cannot be filtered with WHERE
			since it does not exist until GROUP BY runs.
		
		Query 7.4 uses three independent subqueries	with no FROM clause in the outer query —
			the same pattern introduced in Section 3 query 3.5 for comparing independent aggregates
			that share no common key.
*/
-- ============================================================
--  SECTION 7: GROWTH & OPPORTUNITY INSIGHTS
-- ============================================================

-- 7.1  Member acquisition trend year over year
-- What is new members coming trend over the years?

SELECT 
	YEAR(registration_date) AS year,
	COUNT(*) AS new_members,
	LAG(COUNT(*)) OVER(ORDER BY YEAR(registration_date))	AS previous_year,
	COUNT(*) - LAG(COUNT(*)) OVER (ORDER BY YEAR(registration_date))	AS yoy_difference,
	ROUND((COUNT(*) - LAG(COUNT(*)) OVER (ORDER BY YEAR(registration_date))) * 100.0 
		/ NULLIF(LAG(COUNT(*)) OVER (ORDER BY YEAR(registration_date)), 0), 2) AS yoy_growth_pct 
	-- SUM(membership_price_eur)	AS	potential_annual_revenue_eur
FROM dbo.members
GROUP BY YEAR(registration_date)
ORDER BY year

-- 7.2  Upgrade opportunity: high-visit Basic/Student members
-- What are the members that potentially could be upgraded to Premium/VIP?

SELECT TOP 20
	m.member_id,
	m.first_name + ' ' + m.last_name	AS member_name,
	m.membership_type,
	m.membership_price_eur,
	COUNT(a.attendance_id)	AS visits_last_year,
	ROUND( 65 - m.membership_price_eur, 2)	AS potential_upgrade_gain_eur,
	'Consider upgrade to Premium/VIP'   AS recommendation
from dbo.members m
JOIN dbo.attendance a
ON m.member_id = a.member_id
WHERE membership_type IN ('Basic', 'Student', 'Day Pass')
	AND m.status = 'Active'
	AND a.check_in_time >= DATEADD(YEAR, - 1, GETDATE())
GROUP BY 	m.member_id,
	m.first_name + ' ' + m.last_name,
	m.membership_type,
	m.membership_price_eur
HAVING COUNT(a.attendance_id) >= 20
ORDER BY visits_last_year DESC

-- 7.3  Gender split of active members

SELECT 
	gender,
	COUNT(*)	AS total_members,
	ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM dbo.members WHERE status = 'Active'), 2)	AS pct
FROM dbo.members
WHERE status = 'Active'
GROUP BY gender
ORDER BY total_members DESC

-- 7.4  Revenue per active member

SELECT 
	-- what members are priced at
	ROUND(
        (SELECT AVG(membership_price_eur) FROM dbo.members 
         WHERE status = 'Active')
    , 2)                                AS avg_membership_price_eur,
	
    -- what the gym actually collects per member
	ROUND(
		(SELECT SUM(amount_eur) FROM dbo.payments WHERE status = 'Paid') 
		/
		(SELECT COUNT(*) FROM dbo.members WHERE status = 'Active')
		,2)		AS revenue_per_active_member,
  -- difference between the two
	ROUND(
		((SELECT SUM(amount_eur) FROM dbo.payments WHERE status = 'Paid')
		/
		(SELECT COUNT(*) FROM dbo.members WHERE status = 'Active'))
		-
		(SELECT AVG(membership_price_eur) FROM dbo.members 
     WHERE status = 'Active')
	, 2) AS difference_eur
	
	





