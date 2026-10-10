---
name: quant
description: Get econometrics help for a finance research task -- regression diagnostics, panel data, event studies or results write-up
---
$ARGUMENTS

Treat $ARGUMENTS as the user's quant/econometrics task (e.g. "check my OLS for heteroskedasticity in Stata", "event study around earnings announcements in Python", "FE vs RE for my firm-year panel").

1. **Classify** the task and use the matching skill:
   - OLS assumptions, robust/HAC standard errors, multicollinearity, functional form → `regression-diagnostics`
   - Firm-year or country-year panels, fixed vs random effects, clustering, Fama-MacBeth → `panel-data`
   - Abnormal returns around events, CARs, significance tests → `event-study`
   - Turning output into a table, interpreting coefficients, citing methods → `results-writeup`
2. **Check what is missing** before answering: software (Python/R/Stata), data structure (cross-section, time series, panel), frequency, sample, and variables. Ask for anything that changes the answer; otherwise state assumptions explicitly.
3. **Answer** with workings shown (unless the user asked for the direct result only), code in their tool, and an **Assumptions & gaps** section at the end.

If $ARGUMENTS is empty, ask what model or dataset the user is working on and which software they are using.
