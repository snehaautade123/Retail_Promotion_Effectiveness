# Portfolio and Resume Summary

## One-line portfolio description

Built a retail promotion-analysis workflow using Python, PostgreSQL, SQL, Power BI, and DAX to aggregate transaction-level data into product–store–week metrics and compare observed sales patterns across promotion support, departments, stores, and discount bands.

## Resume bullets — use after the release gate is resolved

- Built a Python ETL process to validate and load large retail CSV datasets into PostgreSQL, including transaction, product, and weekly promotion-support data.
- Wrote SQL transformations to aggregate sales, units, basket counts, and discount metrics at product–store–week grain and combine them with promotion-support flags.
- Developed a two-page Power BI report with DAX KPIs, weekly trends, department/product comparisons, discount-band analysis, and interactive slicers.
- Reconciled key Power BI KPIs to like-for-like SQL calculations and documented the observational limitations of promotion comparisons.

Do not add quantified impact (for example, “increased sales by X%”) unless the analysis supports it and you can explain the calculation in an interview.

## LinkedIn project description

Retail Promotion Performance Analysis | Python, PostgreSQL, SQL, Power BI, DAX

An end-to-end retail analytics case study exploring observed sales patterns across display and mailer promotion support, departments, stores, and discount levels. I built a Python-based raw-data loading workflow, SQL product–store–week aggregations, and a two-page Power BI dashboard with interactive filters and KPI measures. The analysis is descriptive rather than causal, and the project includes explicit data-quality validation before final recommendations are made.

## Interview talk track

**Problem:** Retailers need a consistent way to compare sales across promotion-support patterns without mistaking raw totals for promotion effectiveness.

**Approach:** Load source CSVs into PostgreSQL, aggregate transactions to product–store–week grain, combine them with weekly promotion-support indicators, and explore results in Power BI.

**Business judgement:** A higher observed average does not prove that a promotion caused higher sales. Exposure differences, unmatched promotion records, and extreme quantity values need to be checked before recommending a promotion strategy.

**Current limitation to own honestly:** The current filtered KPI values match SQL, but a material gap between all-row totals and promotion-classified totals still needs explanation. Do not present the project as fully validated until this release gate is closed.
