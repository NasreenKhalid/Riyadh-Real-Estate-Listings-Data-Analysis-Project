🏠 **Riyadh Real Estate Market Analysis (2021–2024)**

📌 **Project Overview**
An end-to-end data analysis project examining 1,200 property listings across 20 districts in Riyadh, Saudi Arabia — covering price trends, district comparisons, property type breakdown, and market dynamics from 2021 to 2024.
This project was built to demonstrate a complete data analyst workflow using real-world Saudi market data and Vision 2030 context.

🔑 Key Findings

+20.47% price growth over 3 years — Riyadh property market shows strong upward trajectory driven by Vision 2030 mega-projects and sustained buyer demand
Al Olaya is the most expensive district at SAR 1.59M average — more than 2× cheaper districts like Al Maather, with Central zone dominating the premium tier
Apartments dominate supply (38.9%) but Villas lead in value at SAR 2.2M average — nearly 9× the price of a Studio unit
Area is the strongest price driver — the scatter analysis confirms a clear diagonal relationship between property size and price across all property types
Average 90.6 days on market — properties in high-demand districts sell significantly faster, indicating localised hot markets within the city


🛠️ **Tools Used**
ExcelDashboard, pivot tables, KPI cards, 6 interactive charts
SQL (SQLite)Data querying, YoY growth analysis, district ranking, window functions
Python (pandas, matplotlib)Data cleaning, EDA, feature engineering, visualisations
GitHubVersion control and portfolio hosting

📁 Project Structure
riyadh-realestate-analysis/
│
├── riyadh_realestate_dataset.csv     # Raw dataset — 1,200 listings, 14 columns
├── Riyadh_RealEstate_Analysis.xlsx   # Excel workbook with dashboard + pivot analysis
├── riyadh_analysis_queries.sql       # 15 SQL queries across 5 analysis sections
├── riyadh_analysis.py                # Python EDA script with 6 chart outputs
└── README.md                         # This file

📊 Dashboard Features
The Excel dashboard includes:

5 KPI cards — Total Listings, Avg Price, Median SAR/sqm, Price Growth, Avg Days Listed
Price Trend by Year — Line chart showing 2021–2024 trajectory
Price by Property Type — Horizontal bar chart ranked by average price
Property Type Distribution — Donut chart showing market composition
Top 10 Districts by AVG Price — Colour-coded by zone (Central / North / East-West)
Price vs Area Scatter Plot — Coloured by property type, showing size-price relationship
5 Interactive Slicers — Filter by District, Property Type, Year, Furnished status, Zone


🗄️ SQL Analysis Highlights
The SQL file covers 5 sections of analysis:
sql-- Example: Year-over-year price growth using LAG window function
WITH yearly_avg AS (
    SELECT year, AVG(price_sar) AS avg_price
    FROM riyadh_listings
    GROUP BY year
),
with_lag AS (
    SELECT year, avg_price,
           LAG(avg_price) OVER (ORDER BY year) AS prev_avg
    FROM yearly_avg
)
SELECT year,
       ROUND(avg_price / 1000000.0, 3) AS avg_price_m,
       ROUND((avg_price - prev_avg) / prev_avg * 100, 1) AS yoy_growth_pct
FROM with_lag
ORDER BY year;
Key SQL techniques used: CTEs (WITH clauses), Window functions (LAG, RANK), Conditional aggregation, HAVING filters, Cross joins for index calculation

🐍 Python Analysis
The Python script performs:

Data quality checks and null value validation
Feature engineering (price_bracket, age_group, log_price)
Descriptive statistics and correlation matrix
6 matplotlib visualisations including box plots, bar charts, and scatter plots

python# Key insight from correlation matrix
# price_sar vs area_sqm correlation: 0.90 — very strong relationship
df[['price_sar','price_per_sqm','area_sqm','days_on_market']].corr()


💡 Business Insights & Recommendations
For buyers: The 2022 price dip shows that market corrections do happen — monitoring quarterly trends gives buyers a timing advantage. Al Narjis and Al Nakheel (North zone) offer mid-range pricing with strong growth potential.
For investors: The 20%+ appreciation over 3 years outpaces typical savings returns. Districts adjacent to Vision 2030 development corridors are likely to see above-average growth.
For sellers: Properties priced above the district average stay on market significantly longer. Pricing at or slightly below the district median SAR/sqm reduces time-to-sale.

👩‍💻 About
Nasreen Shehzad — Data Analyst | Business Analyst | KSA-based
Transitioning into data analytics with a background in Business Analysis and Web Development. 
Currently pursuing Google Data Analytics Certificate (Coursera).
