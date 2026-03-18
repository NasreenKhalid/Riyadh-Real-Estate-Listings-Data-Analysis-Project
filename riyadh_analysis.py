"""
Riyadh Real Estate Price Analysis — Python Portfolio Script
Author: [Your Name]
Tools: pandas, matplotlib, numpy
Purpose: EDA + visualizations for portfolio
"""

import pandas as pd
import numpy as np
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import matplotlib.ticker as mticker
import warnings
warnings.filterwarnings('ignore')

# ── Load data ────────────────────────────────────────────────
df = pd.read_csv('/home/claude/riyadh_realestate.csv')
print(f"Dataset loaded: {len(df):,} rows, {df.shape[1]} columns")
print(df.dtypes)

# ── STEP 1: Data Cleaning & Validation ──────────────────────
print("\n=== STEP 1: DATA QUALITY CHECK ===")
print("Null values:\n", df.isnull().sum())
print("\nPrice range: SAR", f"{df['price_sar'].min():,}", "–", f"{df['price_sar'].max():,}")
print("Area range:", df['area_sqm'].min(), "–", df['area_sqm'].max(), "sqm")
print("Years covered:", sorted(df['year'].unique()))

# Flag potential outliers (IQR method)
Q1 = df['price_sar'].quantile(0.25)
Q3 = df['price_sar'].quantile(0.75)
IQR = Q3 - Q1
outliers = df[(df['price_sar'] < Q1 - 1.5*IQR) | (df['price_sar'] > Q3 + 1.5*IQR)]
print(f"\nOutliers detected (IQR method): {len(outliers)} listings ({len(outliers)/len(df)*100:.1f}%)")

# ── STEP 2: Feature Engineering ─────────────────────────────
print("\n=== STEP 2: FEATURE ENGINEERING ===")

# Price brackets
df['price_bracket'] = pd.cut(df['price_sar'],
    bins=[0, 500_000, 1_000_000, 2_000_000, 5_000_000],
    labels=['Under 500K', '500K–1M', '1M–2M', '2M+'])

# Age group
df['age_group'] = pd.cut(df['building_age_years'],
    bins=[-1, 0, 3, 7, 15, 100],
    labels=['New', '1–3 yrs', '4–7 yrs', '8–15 yrs', '15+ yrs'])

# Log price for distribution analysis
df['log_price'] = np.log(df['price_sar'])

print("Features added: price_bracket, age_group, log_price")

# ── STEP 3: Descriptive Statistics ──────────────────────────
print("\n=== STEP 3: DESCRIPTIVE STATS ===")
print(df[['price_sar','price_per_sqm','area_sqm','days_on_market']].describe().round(0))

print("\nAvg price by property type:")
print(df.groupby('property_type')['price_sar'].agg(['mean','median','count']).sort_values('mean', ascending=False).round(0))

# ── STEP 4: Analysis Functions ───────────────────────────────

def price_trend_by_year():
    """Year-over-year price trend with growth rate"""
    yr = df.groupby('year')['price_sar'].agg(['mean','median','count']).reset_index()
    yr['yoy_growth'] = yr['mean'].pct_change() * 100
    return yr

def district_ranking():
    """Full district price ranking"""
    return df.groupby(['district','district_zone']).agg(
        avg_price=('price_sar','mean'),
        median_price=('price_sar','median'),
        count=('price_sar','count'),
        avg_sqm=('price_per_sqm','mean'),
        avg_days=('days_on_market','mean')
    ).sort_values('avg_price', ascending=False).round(0)

def correlation_matrix():
    """Correlations between numeric features"""
    num_cols = ['price_sar','area_sqm','price_per_sqm','bedrooms',
                'building_age_years','days_on_market']
    return df[num_cols].corr().round(2)

print("\n=== YEAR TREND ===")
print(price_trend_by_year().to_string())

print("\n=== TOP 5 DISTRICTS ===")
print(district_ranking().head(5).to_string())

print("\n=== CORRELATIONS ===")
print(correlation_matrix().to_string())

# ── STEP 5: VISUALIZATIONS ──────────────────────────────────
print("\n=== STEP 5: GENERATING CHARTS ===")

COLORS = {'main':'#1B3A6B','teal':'#1A7FB5','orange':'#C0602A',
          'green':'#2E9E6B','gold':'#C9A84C','red':'#992222','grey':'#F5F7FA'}
plt.rcParams['font.family'] = 'Arial'
plt.rcParams['axes.spines.top'] = False
plt.rcParams['axes.spines.right'] = False

fig, axes = plt.subplots(2, 3, figsize=(18, 11))
fig.suptitle('Riyadh Real Estate Market Analysis 2021–2024',
             fontsize=16, fontweight='bold', color=COLORS['main'], y=1.01)

# 1. Price trend by year
ax = axes[0, 0]
yr = price_trend_by_year()
bars = ax.bar(yr['year'].astype(str), yr['mean']/1e6,
              color=[COLORS['teal'],COLORS['teal'],COLORS['main'],COLORS['orange']],
              width=0.5, alpha=0.9, edgecolor='white')
for bar, val in zip(bars, yr['mean']):
    ax.text(bar.get_x()+bar.get_width()/2, val/1e6+0.02, f'SAR {val/1e6:.2f}M',
            ha='center', va='bottom', fontsize=9, fontweight='bold', color=COLORS['main'])
ax.set_title('Average Sale Price by Year', fontweight='bold', color=COLORS['main'])
ax.set_ylabel('SAR (Millions)')
ax.yaxis.set_major_formatter(mticker.FormatStrFormatter('%.1fM'))
ax.set_ylim(0, yr['mean'].max()/1e6 * 1.25)
ax.grid(axis='y', alpha=0.3)

# 2. Price by property type (horizontal bars)
ax = axes[0, 1]
pt = df.groupby('property_type')['price_sar'].mean().sort_values()
colors_pt = [COLORS['teal'] if v < pt.median() else COLORS['main'] for v in pt]
bars2 = ax.barh(pt.index, pt.values/1e6, color=colors_pt, alpha=0.9, height=0.55)
for bar, val in zip(bars2, pt.values):
    ax.text(val/1e6+0.02, bar.get_y()+bar.get_height()/2,
            f'SAR {val/1e6:.2f}M', va='center', fontsize=9, color=COLORS['main'])
ax.set_title('Avg Price by Property Type', fontweight='bold', color=COLORS['main'])
ax.set_xlabel('SAR (Millions)')
ax.grid(axis='x', alpha=0.3)

# 3. Top 10 districts
ax = axes[0, 2]
dist10 = df.groupby('district')['price_sar'].mean().sort_values(ascending=False).head(10)
bar_colors = [COLORS['orange'] if i < 3 else COLORS['teal'] for i in range(10)]
bars3 = ax.barh(dist10.index[::-1], dist10.values[::-1]/1e6,
                color=bar_colors[::-1], alpha=0.9, height=0.6)
ax.set_title('Top 10 Districts by Avg Price', fontweight='bold', color=COLORS['main'])
ax.set_xlabel('SAR (Millions)')
ax.grid(axis='x', alpha=0.3)

# 4. Price distribution by type (box plot)
ax = axes[1, 0]
types_order = df.groupby('property_type')['price_sar'].median().sort_values(ascending=False).index
data_box = [df[df['property_type']==t]['price_sar'].values/1e6 for t in types_order]
bp = ax.boxplot(data_box, labels=types_order, patch_artist=True,
                medianprops=dict(color='white', linewidth=2))
box_colors = [COLORS['main'],COLORS['orange'],COLORS['teal'],COLORS['green'],COLORS['gold']]
for patch, color in zip(bp['boxes'], box_colors):
    patch.set_facecolor(color); patch.set_alpha(0.8)
ax.set_title('Price Distribution by Type', fontweight='bold', color=COLORS['main'])
ax.set_ylabel('SAR (Millions)')
ax.grid(axis='y', alpha=0.3)
ax.tick_params(axis='x', rotation=15)

# 5. SAR/sqm by district zone
ax = axes[1, 1]
zone_psm = df.groupby(['district_zone','year'])['price_per_sqm'].mean().unstack()
x = np.arange(len(zone_psm))
width = 0.2
zone_colors = [COLORS['main'], COLORS['teal'], COLORS['orange'], COLORS['green']]
for i, (yr_val, color) in enumerate(zip(zone_psm.columns, zone_colors)):
    ax.bar(x + i*width, zone_psm[yr_val], width, label=str(yr_val),
           color=color, alpha=0.85)
ax.set_xticks(x + width*1.5); ax.set_xticklabels(zone_psm.index)
ax.set_title('SAR/sqm by Zone per Year', fontweight='bold', color=COLORS['main'])
ax.set_ylabel('SAR per sqm')
ax.legend(title='Year', fontsize=8); ax.grid(axis='y', alpha=0.3)

# 6. Price growth 2021 vs 2024
ax = axes[1, 2]
growth = df[df['year'].isin([2021, 2024])].groupby(['year','property_type'])['price_sar'].mean().unstack()
if 2021 in growth.index and 2024 in growth.index:
    pct_change = ((growth.loc[2024] - growth.loc[2021]) / growth.loc[2021] * 100).sort_values(ascending=False)
    bar_clrs = [COLORS['green'] if v > 0 else COLORS['red'] for v in pct_change]
    ax.bar(pct_change.index, pct_change.values, color=bar_clrs, alpha=0.9, width=0.5)
    for i, (idx, val) in enumerate(pct_change.items()):
        ax.text(i, val+0.5, f'+{val:.1f}%', ha='center', fontsize=9,
                fontweight='bold', color=COLORS['main'])
ax.set_title('Price Growth 2021→2024 by Type', fontweight='bold', color=COLORS['main'])
ax.set_ylabel('% Growth')
ax.grid(axis='y', alpha=0.3)
ax.tick_params(axis='x', rotation=15)

plt.tight_layout()
plt.savefig('/home/claude/riyadh_analysis_charts.png', dpi=150, bbox_inches='tight',
            facecolor='white')
plt.close()
print("Charts saved: riyadh_analysis_charts.png")

# ── STEP 6: Summary Insights ────────────────────────────────
print("\n=== KEY INSIGHTS ===")
avg_growth = (df[df['year']==2024]['price_sar'].mean() / df[df['year']==2021]['price_sar'].mean() - 1) * 100
top_dist = df.groupby('district')['price_sar'].mean().idxmax()
best_value = df.groupby('district').apply(lambda x: x['area_sqm'].mean() / x['price_per_sqm'].mean()).idxmax()
fastest = df.groupby('district')['days_on_market'].mean().idxmin()

print(f"1. Overall price growth 2021–2024: +{avg_growth:.1f}%")
print(f"2. Most expensive district: {top_dist}")
print(f"3. Best value district (area/price ratio): {best_value}")
print(f"4. Fastest-selling district: {fastest}")
print(f"5. Furnished premium: SAR {df[df['furnished']=='Furnished']['price_sar'].mean() - df[df['furnished']=='Unfurnished']['price_sar'].mean():,.0f}")
print(f"6. New vs 15+ yr old price gap: SAR {df[df['building_age_years']==0]['price_sar'].mean() - df[df['building_age_years']>=15]['price_sar'].mean():,.0f}")
