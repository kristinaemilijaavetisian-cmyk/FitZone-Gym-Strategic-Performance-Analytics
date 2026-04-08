-- ============================================================
/*
Section 3 — Financial Performance

This section examines where the gym's revenue comes from, how reliably it is collected, 
and whether the cost of coaching staff is sustainable relative to income.

	Query 3.1	breaks down paid revenue month by month,
				showing gross revenue, transaction count, and average
				transaction value per month —
				enabling management to spot seasonal revenue patterns
				and track whether the business is growing over time.

	Query 3.2	groups paid revenue by membership type,
				revealing which tiers generate the most income.
				Combined with query 1.1 (member count by tier),
				this helps identify whether high-value plans
				are being sold enough relative to their potential.

	Query 3.3	shows which payment methods are used most
				and what share of total revenue each one represents —
				useful for decisions about payment infrastructure
				and whether certain methods should be promoted or removed.

	Query 3.4	quantifies revenue leakage by surfacing the total value
				of failed and pending payments —
				money the gym should have collected but did not.
				This is a direct action target: following up on pending
				payments or fixing failed billing can recover real revenue.

	Query 3.5	compares total monthly coach payroll against
				average monthly revenue, expressing the relationship
				as a percentage. The fitness industry benchmark
				for a healthy gym is a payroll-to-revenue ratio below 40%.
				Note: payroll here reflects coach salaries only —
				full staff costs would produce a higher percentage.

Technical notes:

		all revenue queries filter WHERE status = 'Paid' to exclude
		failed, pending, and refunded transactions from financial totals.
		Query 3.3 uses a subquery in SELECT for percentage share
		without needing a JOIN or CTE.
		Query 3.5 uses nested subqueries with no FROM clause —
		a pattern suited for comparing two independent aggregates
		that share no common key.
		NULLIF protects all division operations from divide-by-zero errors.
*/
-- ============================================================

-- ============================================================
--  SECTION 3: FINANCIAL PERFORMANCE
-- ============================================================

-- 3.1  Monthly revenue (paid only)
-- How much does gym make in month (paid only clients)?

SELECT 
	FORMAT(payment_date, 'yyyy-MM')	AS month,
	SUM(amount_eur) AS gross_revenue_eur,
	COUNT(*) AS transactions,
	ROUND(AVG(amount_eur), 2)	AS avg_transaction_eur
FROM dbo.payments
WHERE status = 'Paid'
GROUP BY FORMAT(payment_date, 'yyyy-MM')
ORDER BY month

-- 3.2  Revenue by membership type
-- How much does gym make through various membership types? Which types are paying the most?

SELECT 
	membership_type,
	SUM(amount_eur)		AS gross_revenue_eur,
	COUNT(*)	AS payment_count,
	ROUND(AVG(amount_eur), 2)	AS avg_payment_eur
FROM dbo.payments
WHERE status = 'Paid'
GROUP BY 
	membership_type
ORDER BY gross_revenue_eur DESC

-- 3.3  Payment method breakdown
-- Which payment methods do generate most revenue?

SELECT 
	payment_method,
	COUNT(*)	 AS transactions,
	SUM(amount_eur)		AS total_eur,
	ROUND(SUM(amount_eur) * 100.0 / (SELECT SUM(amount_eur) FROM dbo.payments WHERE status = 'Paid'), 2) AS revenue_pct
FROM dbo.payments
WHERE status = 'Paid'
GROUP BY payment_method
ORDER BY total_eur DESC
	
-- 3.4  Failed & pending payments (revenue leakage)
-- How much money could be made because of failed & pending payments?

SELECT 
	status,
	COUNT(*)	AS transactions,
	SUM(amount_eur)		AS potential_revenue
FROM dbo.payments
WHERE status IN ('Failed', 'Pending')
GROUP BY status

-- 3.5  Total coach payroll vs average monthly revenue

			SELECT
    -- one month of coach payroll
    ROUND(
        (SELECT SUM(monthly_salary_eur) FROM dbo.coaches WHERE active = 1)
    , 2)                                        AS monthly_payroll_eur,

    -- one average month of revenue
    ROUND(
        (SELECT SUM(amount_eur) FROM dbo.payments WHERE status = 'Paid')
        /
        NULLIF(DATEDIFF(MONTH,
            (SELECT MIN(payment_date) FROM dbo.payments WHERE status = 'Paid'),
            (SELECT MAX(payment_date) FROM dbo.payments WHERE status = 'Paid')
        ), 0)
    , 2)                                        AS avg_monthly_revenue_eur,

    -- payroll as % of revenue
    ROUND(
        (SELECT SUM(monthly_salary_eur) FROM dbo.coaches WHERE active = 1)
        * 100.0 /
        NULLIF(
            (SELECT SUM(amount_eur) FROM dbo.payments WHERE status = 'Paid')
            /
            NULLIF(DATEDIFF(MONTH,
                (SELECT MIN(payment_date) FROM dbo.payments WHERE status = 'Paid'),
                (SELECT MAX(payment_date) FROM dbo.payments WHERE status = 'Paid')
            ), 0)
        , 0)
    , 2)                                        AS payroll_pct_of_revenue
	-- Note: payroll here reflects coach salaries only.
    -- Full staff payroll would produce a higher percentage.