-- ============================================================
-- RIYADH REAL ESTATE ANALYSIS — SQL PORTFOLIO SCRIPTS
-- Author: [Your Name]
-- Dataset: 1,200 Riyadh property listings (2021–2024)
-- Tool: SQLite / PostgreSQL / MySQL compatible
-- ============================================================

-- ── SETUP ───────────────────────────────────────────────────
-- Run this first to create the table (if importing from CSV)
CREATE TABLE IF NOT EXISTS riyadh_listings (
    listing_id        INTEGER PRIMARY KEY,
    district          TEXT,
    property_type     TEXT,
    year              INTEGER,
    quarter           TEXT,
    area_sqm          INTEGER,
    bedrooms          INTEGER,
    bathrooms         INTEGER,
    price_sar         INTEGER,
    price_per_sqm     REAL,
    building_age_years INTEGER,
    furnished         TEXT,
    days_on_market    INTEGER,
    district_zone     TEXT
);

-- ============================================================
-- SECTION 1: EXPLORATORY DATA ANALYSIS (EDA)
-- ============================================================

-- 1.1 Basic dataset overview
SELECT
    COUNT(*)                         AS total_listings,
    COUNT(DISTINCT district)         AS unique_districts,
    COUNT(DISTINCT property_type)    AS property_types,
    MIN(year) || '–' || MAX(year)    AS year_range,
    ROUND(AVG(price_sar) / 1000000.0, 2) AS avg_price_millions,
    ROUND(MIN(price_sar) / 1000.0, 0)    AS min_price_k,
    ROUND(MAX(price_sar) / 1000000.0, 2) AS max_price_millions
FROM riyadh_realestate_dataset;


-- 1.2 Distribution by property type
SELECT
    property_type,
    COUNT(*)                               AS listings,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM riyadh_realestate_dataset), 1) AS pct,
    ROUND(AVG(price_sar) / 1000000.0, 2)  AS avg_price_m,
    ROUND(AVG(price_per_sqm), 0)          AS avg_sar_per_sqm
FROM riyadh_realestate_dataset
GROUP BY property_type
ORDER BY avg_price_m DESC;


-- 1.3 Listings per year (volume trend)
SELECT
    year,
    COUNT(*)                                AS listings,
    ROUND(AVG(price_sar) / 1000000.0, 2)   AS avg_price_m,
    ROUND(AVG(price_per_sqm), 0)           AS avg_sar_sqm
FROM riyadh_realestate_dataset
GROUP BY year
ORDER BY year;


-- ============================================================
-- SECTION 2: PRICE TREND ANALYSIS
-- ============================================================

-- 2.1 Year-over-year price growth (overall)
WITH yearly_avg AS (
    SELECT
        year,
        AVG(price_sar) AS avg_price
    FROM riyadh_realestate_dataset
    GROUP BY year
),
with_lag AS (
    SELECT
        year,
        avg_price,
        LAG(avg_price) OVER (ORDER BY year) AS prev_avg
    FROM yearly_avg
)
SELECT
    year,
    ROUND(avg_price / 1000000.0, 3)          AS avg_price_m,
    ROUND((avg_price - prev_avg) / prev_avg * 100, 1) AS yoy_growth_pct
FROM with_lag
ORDER BY year;


-- 2.2 Quarterly price trend with rolling index (base Q1 2021 = 100)
WITH base AS (
    SELECT AVG(price_sar) AS base_price
    FROM riyadh_realestate_dataset
    WHERE year = 2021 AND quarter = 'Q1'
),
quarterly AS (
    SELECT
        year,
        quarter,
        AVG(price_sar) AS avg_price,
        COUNT(*)        AS listings
    FROM riyadh_realestate_dataset
    GROUP BY year, quarter
)
SELECT
    q.year,
    q.quarter,
    ROUND(q.avg_price / 1000000.0, 3)     AS avg_price_m,
    q.listings,
    ROUND(q.avg_price / b.base_price * 100, 1) AS price_index
FROM quarterly q, base b
ORDER BY q.year, q.quarter;


-- 2.3 Price growth by property type (2021 vs 2024)
SELECT
    property_type,
    ROUND(AVG(CASE WHEN year = 2021 THEN price_sar END) / 1000000.0, 2) AS avg_2021_m,
    ROUND(AVG(CASE WHEN year = 2024 THEN price_sar END) / 1000000.0, 2) AS avg_2024_m,
    ROUND(
        (AVG(CASE WHEN year = 2024 THEN price_sar END) -
         AVG(CASE WHEN year = 2021 THEN price_sar END)) /
         AVG(CASE WHEN year = 2021 THEN price_sar END) * 100
    , 1) AS growth_pct_3yr
FROM riyadh_realestate_dataset
GROUP BY property_type
ORDER BY growth_pct_3yr DESC;


-- ============================================================
-- SECTION 3: DISTRICT ANALYSIS
-- ============================================================

-- 3.1 Full district ranking by avg price
SELECT
    RANK() OVER (ORDER BY AVG(price_sar) DESC) AS price_rank,
    district,
    district_zone,
    COUNT(*)                                   AS listings,
    ROUND(AVG(price_sar) / 1000000.0, 2)       AS avg_price_m,
    ROUND(AVG(price_per_sqm), 0)               AS avg_sar_sqm,
    ROUND(AVG(days_on_market), 0)              AS avg_days_listed
FROM riyadh_realestate_dataset
GROUP BY district, district_zone
ORDER BY avg_price_m DESC;


-- 3.2 Districts with fastest vs slowest sales
SELECT
    district,
    ROUND(AVG(days_on_market), 0) AS avg_days_on_market,
    COUNT(*)                      AS listings,
    CASE
        WHEN AVG(days_on_market) < 45  THEN 'Hot market'
        WHEN AVG(days_on_market) < 90  THEN 'Active'
        WHEN AVG(days_on_market) < 130 THEN 'Moderate'
        ELSE 'Slow market'
    END AS market_tempo
FROM riyadh_realestate_dataset
GROUP BY district
ORDER BY avg_days_on_market;


-- 3.3 Price premium of top 5 vs bottom 5 districts
WITH ranked AS (
    SELECT
        district,
        AVG(price_sar) AS avg_price,
        RANK() OVER (ORDER BY AVG(price_sar) DESC) AS rnk,
        COUNT(*) AS cnt
    FROM riyadh_realestate_dataset
    GROUP BY district
),
tiers AS (
    SELECT district, avg_price, 'Top 5' AS tier FROM ranked WHERE rnk <= 5
    UNION ALL
    SELECT district, avg_price, 'Bottom 5' FROM ranked WHERE rnk > 15
)
SELECT
    tier,
    ROUND(AVG(avg_price) / 1000000.0, 2) AS avg_price_m,
    ROUND(
        (MAX(CASE WHEN tier='Top 5' THEN avg_price END) -
         MAX(CASE WHEN tier='Bottom 5' THEN avg_price END)) /
         MAX(CASE WHEN tier='Bottom 5' THEN avg_price END) * 100
    , 0) AS premium_pct
FROM tiers
GROUP BY tier;


-- ============================================================
-- SECTION 4: PROPERTY FEATURE ANALYSIS
-- ============================================================

-- 4.1 Furnished vs unfurnished: price and speed
SELECT
    furnished,
    COUNT(*)                              AS listings,
    ROUND(AVG(price_sar) / 1000000.0, 2) AS avg_price_m,
    ROUND(AVG(price_per_sqm), 0)         AS avg_sar_sqm,
    ROUND(AVG(days_on_market), 0)        AS avg_days_to_sell
FROM riyadh_realestate_dataset
GROUP BY furnished
ORDER BY avg_price_m DESC;


-- 4.2 Building age impact on price per sqm
SELECT
    CASE
        WHEN building_age_years = 0           THEN '🟢 New (0 yrs)'
        WHEN building_age_years BETWEEN 1 AND 3  THEN '🟡 1–3 yrs'
        WHEN building_age_years BETWEEN 4 AND 7  THEN '🟠 4–7 yrs'
        WHEN building_age_years BETWEEN 8 AND 15 THEN '🔴 8–15 yrs'
        ELSE '⚫ 15+ yrs'
    END AS age_group,
    COUNT(*)                              AS listings,
    ROUND(AVG(price_sar) / 1000000.0, 2) AS avg_price_m,
    ROUND(AVG(price_per_sqm), 0)         AS avg_sar_sqm
FROM riyadh_realestate_dataset
GROUP BY age_group
ORDER BY avg_price_m DESC;


-- 4.3 Apartments: bedrooms vs price analysis
SELECT
    bedrooms,
    COUNT(*)                              AS listings,
    ROUND(AVG(area_sqm), 0)              AS avg_area_sqm,
    ROUND(AVG(price_sar) / 1000.0, 0)   AS avg_price_k,
    ROUND(AVG(price_per_sqm), 0)        AS avg_sar_sqm,
    ROUND(AVG(days_on_market), 0)       AS avg_days
FROM riyadh_realestate_dataset
WHERE property_type = 'Apartment'
GROUP BY bedrooms
ORDER BY bedrooms;


-- ============================================================
-- SECTION 5: ADVANCED ANALYSIS
-- ============================================================

-- 5.1 Price outlier detection (listings > 2 std devs from mean)
WITH stats AS (
    SELECT
        AVG(price_sar)   AS mean_price,
        AVG(price_sar * price_sar) - AVG(price_sar) * AVG(price_sar) AS variance
    FROM riyadh_realestate_dataset
),
with_z AS (
    SELECT
        listing_id, district, property_type, price_sar,
        ROUND((price_sar - s.mean_price) /
              SQRT(s.variance + 0.0001), 2) AS z_score
    FROM riyadh_realestate_dataset, stats s
)
SELECT *
FROM with_z
WHERE ABS(z_score) > 2
ORDER BY z_score DESC
LIMIT 20;


-- 5.2 Best value districts (high area, lower price/sqm)
SELECT
    district,
    district_zone,
    ROUND(AVG(area_sqm), 0)              AS avg_area_sqm,
    ROUND(AVG(price_per_sqm), 0)        AS avg_sar_sqm,
    ROUND(AVG(price_sar) / 1000000.0, 2) AS avg_price_m,
    COUNT(*)                             AS listings,
    ROUND(AVG(area_sqm) / AVG(price_per_sqm), 2) AS value_score
FROM riyadh_realestate_dataset
GROUP BY district, district_zone
ORDER BY value_score DESC
LIMIT 10;


-- 5.3 District × Year price matrix (pivot)
SELECT
    district,
    ROUND(AVG(CASE WHEN year = 2021 THEN price_sar END) / 1000000.0, 2) AS "2021_M",
    ROUND(AVG(CASE WHEN year = 2022 THEN price_sar END) / 1000000.0, 2) AS "2022_M",
    ROUND(AVG(CASE WHEN year = 2023 THEN price_sar END) / 1000000.0, 2) AS "2023_M",
    ROUND(AVG(CASE WHEN year = 2024 THEN price_sar END) / 1000000.0, 2) AS "2024_M",
    ROUND(
        (AVG(CASE WHEN year = 2024 THEN price_sar END) -
         AVG(CASE WHEN year = 2021 THEN price_sar END)) /
         AVG(CASE WHEN year = 2021 THEN price_sar END) * 100
    , 1) AS growth_pct
FROM riyadh_realestate_dataset
GROUP BY district
ORDER BY growth_pct DESC;
