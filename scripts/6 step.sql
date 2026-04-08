-- ============================================================
/*
Section 6 — Equipment

This section gives management a full picture of the gym's physical assets — what condition they are in, 
what maintenance actions are due, and where capital is invested across the facility.

	Query 6.1	provides a high-level status summary of all equipment, grouped by status (Active, Under Maintenance,
				Out of Service, Retired) with unit counts and total asset value per group. This gives the owner an instant overview of
				how much of their physical investment is actually usable at any given moment, and how much is sitting idle.

	Query 6.2	identifies all active equipment due for maintenance within the next 30 days, ordered by urgency.
				This is a direct action list for the operations team — scheduling maintenance proactively prevents breakdowns
				that take equipment out of service during peak hours and frustrate members.

	Query 6.2b	extends the maintenance view by cross-referencing maintenance dates against warranty expiry dates,
				assigning each piece of equipment a priority flag: 'Priority' means maintenance should be pulled forward
				to be completed before the warranty window closes, 'Warning' means the warranty will expire before the
				scheduled maintenance date and the owner is at risk of paying for repairs that could have been free,
				'OK' means the scheduled maintenance falls safely within the warranty period. This query directly translates 
				into cost savings by ensuring repairs happen while still covered.

	Query 6.3	breaks down equipment investment by location zone, showing total units, active units, total asset value,
				active asset value, and average unit cost per zone. The gap between total and active asset value
				represents the cost of downtime per zone — money invested in equipment that is currently not generating 
				value for members. Combined with attendance data from Section 2, this helps identify whether the most 
				expensive zones are actually the most used ones.

Technical notes:

		Query 6.2b uses DATEDIFF(DAY, next_maintenance_date, warranty_expiry) to calculate the gap between two future dates —
		a negative result means warranty expires before maintenance, which is captured by the Warning flag.
	
		Query 6.3 uses CASE WHEN inside SUM to conditionally aggregate only active equipment costs — a common pattern 
		for calculating a subset total without a subquery or secondary JOIN.
*/
--=============================================================
--  SECTION 6: EQUIPMENT
-- ============================================================

-- 6.1  Equipment status summary

SELECT 
	status,
	COUNT(*) AS units,
	ROUND(SUM(purchase_cost_eur), 2) AS total_value_eur
FROM dbo.equipment
GROUP BY status
ORDER BY units DESC

-- 6.2  Equipment due for maintenance in next 30 days

-- Which equipment do need maintenance in next 30 days?

SELECT 
	equipment_id,
	equipment_name, 
	brand,
	location_zone,
	DATEDIFF(DAY, GETDATE(), next_maintenance_date) AS days_till_maintenance
FROM dbo.equipment
WHERE next_maintenance_date <= DATEADD(DAY, 30, GETDATE())
AND status = 'Active'
ORDER BY days_till_maintenance ASC

-- Which equipment does have a maintenance priority?

SELECT 
	equipment_id,
	equipment_name,
	brand,
	location_zone,
	DATEDIFF(DAY, GETDATE(), warranty_expiry)				AS days_till_warranty_expiration,
	DATEDIFF(DAY, GETDATE(), next_maintenance_date)			AS days_till_maintenance,
	DATEDIFF(DAY, next_maintenance_date, warranty_expiry)	AS days_between,
		CASE
			WHEN DATEDIFF(DAY, next_maintenance_date, warranty_expiry) BETWEEN 0 AND 14 THEN 'Priority - fix before warranty expires'
			WHEN warranty_expiry < next_maintenance_date THEN 'Warning -warranty expires before maintenance'
			ELSE 'OK — warranty covers maintenance'
		END AS warranty_maintenance_flag
FROM dbo.equipment
WHERE warranty_expiry <= DATEADD(DAY, 30, GETDATE()) AND next_maintenance_date <= DATEADD(DAY, 30, GETDATE())
AND status = 'Active'
ORDER BY days_till_warranty_expiration DESC

-- 6.3  Total asset value by zone
-- How much are the assets in different zones worth? Which assets are used the most and is worth investing?

SELECT 
	location_zone,
	COUNT(*)	AS total_units,
	SUM(
		CASE 
			WHEN status = 'Active' THEN 1
			ELSE 0
		END) AS active_units,
	ROUND(SUM(purchase_cost_eur), 2)	AS total_asset_value_eur,
	ROUND(SUM(
		CASE
			WHEN status = 'Active' THEN purchase_cost_eur
			ELSE 0
		END), 1)	AS active_asset_value_eur,
	ROUND(AVG(purchase_cost_eur), 1)	AS avg_cost
FROM dbo.equipment
GROUP BY location_zone
ORDER BY active_asset_value_eur DESC


