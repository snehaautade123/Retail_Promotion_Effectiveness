# Retail Promotion Performance Analysis

**Portfolio project | SQL · Python · PostgreSQL · Power BI · DAX**

## Project status

The two-page Power BI dashboard is built and the `Observed Sales` and `Observed Units` measures reconcile with SQL when both use the same `promotion_type <> 'Unknown'` filter. A broader promotion-coverage reconciliation remains open, so the findings should not yet be presented as final business conclusions.

## Business problem

Retail teams need to understand how observed product sales differ across promotion-support patterns, departments, stores, and discount levels. Comparing raw totals alone can be misleading when products have unequal exposure to each promotion type.

## Objective

Build a repeatable analytical workflow that combines transaction data, product attributes, and weekly promotion-support information, then presents comparable sales patterns in a Power BI dashboard. The analysis is descriptive: it identifies associations in observed data and does **not** establish that a promotion caused a sales increase.

## Dataset

This project uses **dunnhumby — The Complete Journey** dataset. The public source describes household-level transactions over approximately two years for a group of 2,500 frequent-shopping households, along with product and marketing information. The source files include transaction data, product metadata, and weekly promotion-support fields such as `display` and `mailer`.

- Official dataset portal: <https://www.dunnhumby.com/source-files/>
- Download the source data yourself; large raw CSV files should not be committed to GitHub.

## Tools

- **Python:** ETL checks and PostgreSQL loading
- **PostgreSQL:** raw storage, aggregation, joins, and analytical view
- **SQL:** weekly sales aggregation and promotion classification
- **Power BI:** interactive two-page dashboard
- **DAX:** KPI measures and promotion-comparison calculations

## Workflow

```text
Source CSV files
      ↓
Python ETL: validate inputs and load CSVs into PostgreSQL
      ↓
PostgreSQL raw tables
  ├── retail.transactions
  ├── retail.products
  └── retail.causal_raw
      ↓
SQL transformations
  ├── retail.weekly_sales        (product × store × week sales metrics)
  ├── retail.promotion_support   (product × store × week promotion flags)
  └── retail.promotion_analysis  (combined analysis view)
      ↓
Power BI model and DAX measures
      ↓
Promotion Overview + Promotion Deep Dive
```

The current ETL supports a full raw-table load using `--load`. The SQL transformation step should be kept as version-controlled `.sql` files and run after loading; do not describe the current project as a fully automated one-command end-to-end pipeline unless that has been implemented and tested.

## Data model and key logic

### Weekly sales

Sales transactions are aggregated to **product–store–week** grain with the following measures:

- `sales`: sum of `sales_value`
- `units`: sum of `quantity`
- `transactions`: distinct basket count
- `retail_discount`: sum of retail discount
- `coupon_discount`: sum of coupon discount

### Promotion support

The causal/promotion source is grouped by product, store, and week. A display or mailer flag is set when any record for that key indicates the relevant support. Multiple support records for the same key are collapsed into one set of flags.

### Promotion classification

The analysis view classifies records as `Display Only`, `Mailer Only`, `Display + Mailer`, `Neither`, or `Unknown` when no promotion-support key matches. KPI measures that exclude `Unknown` describe **classified observations**, not all sales in the raw transaction history.

## Business questions

1. How do observed sales differ among Display Only, Mailer Only, and Display + Mailer?
2. How do observed sales vary by department and store?
3. How does the weekly sales pattern differ across promotion types?
4. How concentrated are observed sales across discount bands?
5. When comparing promotion types, which products have sufficient observations across types to support a fairer comparison?

## Dashboard

### Page 1 — Promotion Overview

Provides high-level KPIs, observed sales by promotion type, weekly trend, department performance, and promotion exposure. Slicers allow users to explore department, store, promotion type, and week.

![Promotion Overview](Documentation/promotion-overview.png)

### Page 2 — Promotion Deep Dive

Explores department and product performance, observed sales trends, discount levels, and a comparable-product promotion matrix. Results should be interpreted using the filters and comparison rules displayed in the report.

![Promotion Deep Dive](Documentation/promotion-deep-dive.png)

## KPI definitions

- **Observed Sales:** sum of `sales` for rows where `promotion_type` is not `Unknown`.
- **Observed Units:** sum of `units` for rows where `promotion_type` is not `Unknown`.
- **Average Weekly Sales:** use the exact DAX definition in the report model; document the denominator and filter context before publishing a final result.
- **Average Discount %:** derived from the discount fields and sales; interpret this measure only after confirming the source sign convention and the exact formula in the Power BI model.

## Validation status and release gate

The following like-for-like KPI reconciliation has been performed:

| Metric | SQL with `promotion_type <> 'Unknown'` | Power BI card | Status |
|---|---:|---:|---|
| Observed Sales | 1,557,750.83 | 1.56M | Matches after display rounding |
| Observed Units | 794,593 | 795K | Matches after display rounding |

**Open data-quality issue:** across all rows, `promotion_analysis` currently totals `8,057,463.08` in sales and `260,685,622` units. Excluding `Unknown` leaves `1,557,750.83` in sales and `794,593` units. The difference in coverage—especially the unit gap—is large and must be explained before treating the promotion comparison as final. This may reflect unmatched promotion keys or a data/modeling issue; do not claim a promotion is the winner until it is investigated.

## Interpretation and limitations

- These are observational comparisons, not causal estimates of promotion lift.
- Promotion type `Unknown` is excluded from the two `Observed` KPIs, so those KPIs are not totals for all sales.
- Products and weeks may have different promotion exposure; comparisons should use the documented comparable-product logic where relevant.
- Quantity values can contain extreme values in this dataset; review outliers and aggregation behavior before using unit totals for business decisions.
- Raw source files and database credentials must not be committed to the public repository.

## Reproduction notes

1. Download the source CSVs from the official dataset portal.
2. Create a local Python environment and install the dependencies used by `Python_ETL/etl_pipeline.py`.
3. Set local database and file-path configuration without committing secrets.
4. Run the ETL dry-run and resolve any validation errors.
5. Run the raw load with `--load` only when you intend to replace the raw target tables; this operation truncates the configured targets before loading.
6. Run the version-controlled SQL transformations.
7. Refresh the Power BI report and execute the documented QA checks.

Exact local configuration depends on the paths and environment variables defined in the project files. Never place passwords, connection strings containing secrets, or raw data files in GitHub.

## Recommended repository contents

```text
Retail_Promotion_Effectiveness/
├── Python_ETL/
│   └── etl_pipeline.py
├── SQL/
│   ├── 01_build_promotion_support.sql
│   ├── 02_build_weekly_sales.sql
│   ├── 03_create_promotion_analysis.sql
│   └── 04_validation_checks.sql
├── PowerBI/
│   └── Retail_Promotion_Performance.pbix
├── docs/
│   ├── data_dictionary.md
│   └── screenshots/
├── .env.example
├── .gitignore
└── README.md
```

This is the recommended public repository layout; keep only files that actually exist and are safe to share. If the SQL scripts are currently stored elsewhere or still only in pgAdmin history, save and test them before publishing.

## Final business takeaway

The dashboard is designed to show how observed sales patterns differ across promotion-support types and retail segments. Final recommendations should be written only after the promotion-key coverage issue is resolved and the main visual results are reconciled to SQL. Where the evidence is observational, recommend controlled tests rather than claiming causal lift.
