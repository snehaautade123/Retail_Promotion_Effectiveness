# Final Release Checklist — Retail Promotion Performance

Use this as a single close-out list; do not redo completed setup work.

## Must close before calling the project hiring-ready

- [ ] Investigate why `promotion_type <> 'Unknown'` retains 1,557,750.83 of 8,057,463.08 sales but only 794,593 of 260,685,622 units. Check join coverage, key consistency, and quantity outliers; do not modify source data just to make totals match.
- [ ] Validate the primary chart totals by promotion type against PostgreSQL using the same filter and aggregation logic.
- [ ] Confirm the discount measure's sign convention and denominator, then validate one result against SQL.
- [ ] Save the transformations that were run in pgAdmin as checked-in SQL scripts, then test them in documented order.
- [ ] Confirm `.env`, credentials, and raw CSVs are excluded from Git; provide a safe `.env.example` without secrets.
- [ ] Add clear screenshots of both Power BI pages to `docs/screenshots/` and reference them from README.
- [ ] Ensure README dataset attribution, setup instructions, known limitations, and KPI definitions match the final implementation.
- [ ] Only after checks pass, finalize the business findings and add truthful resume/LinkedIn bullets.

## Already confirmed — do not repeat unless something changes

- [x] Raw load succeeded for `retail.transactions` (2,595,732 rows), `retail.products` (92,353 rows), and `retail.causal_raw` (36,786,524 rows).
- [x] `retail.weekly_sales` was rebuilt with 2,370,784 rows.
- [x] `retail.promotion_support` row count returned 36,771,279.
- [x] Both Power BI pages open and display visuals.
- [x] Observed Sales matched between SQL and Power BI with the `Unknown` promotion type excluded, to display rounding.
- [x] Observed Units matched between SQL and Power BI with the `Unknown` promotion type excluded, to display rounding.
