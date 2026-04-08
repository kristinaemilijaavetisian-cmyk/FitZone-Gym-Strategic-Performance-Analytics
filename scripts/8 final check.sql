-- =====================================
-- Final checks
-- =====================================

-- Searching in all tables if they have the correct row counts and no hidden character issues remain:


SELECT 'members'      AS tbl, COUNT(*) AS rows FROM members      UNION ALL
SELECT 'coaches'           , COUNT(*)          FROM coaches       UNION ALL
SELECT 'attendance'        , COUNT(*)          FROM attendance    UNION ALL
SELECT 'payments'          , COUNT(*)          FROM payments      UNION ALL
SELECT 'equipment'         , COUNT(*)          FROM equipment     UNION ALL
SELECT 'group_classes'     , COUNT(*)          FROM group_classes;

SELECT DISTINCT status FROM payments;
SELECT DISTINCT status FROM members;
SELECT DISTINCT employment_type FROM coaches;