---
name: results-writeup
description: Turn regression or event-study output into a publication-style results table and a written interpretation with Harvard-style method citations. Use when the user pastes model output and asks how to present it, interpret coefficients, explain economic significance, or write the results/methodology section.
argument-hint: "[paste output] [python|r|stata]"
---
# Results write-up

## Hard rules
- **Only use numbers from the user's actual output.** Never invent, round away, or "tidy" results. If a number needed for the write-up is missing (e.g. a standard deviation for economic magnitude), ask for it or leave a visible `[NEEDED: ...]` placeholder.
- **Citations: Harvard style.** Only cite sources you are confident exist, with full details. Tell the user to verify every reference against the original paper before submission. Never invent a reference -- if unsure, write `[CITATION NEEDED: topic]`.
- Keep the user's academic register: formal, precise, hedged where the evidence is ("is consistent with", not "proves").

## 1. Regression table conventions (finance)
- Columns = specifications (baseline → added controls → fixed effects → robustness)
- Coefficients with standard errors **or** t-statistics in parentheses (say which in the notes)
- Stars: * p<0.10, ** p<0.05, *** p<0.01 (state in notes)
- Bottom rows: fixed effects (Yes/No), clustering level, N, (within/adjusted) R-squared
- Table notes: variable definitions or reference to an appendix, SE type, sample period

### Producing the table
- **Python**: `from statsmodels.iolib.summary2 import summary_col` → `summary_col([m1, m2], stars=True, info_dict={"N": lambda r: f"{int(r.nobs)}"})`; for `linearmodels` use `compare({...})`; export with `.as_latex()` / `.as_html()` or to Excel via pandas
- **R**: `fixest::etable(m1, m2, tex = FALSE)` or `modelsummary::modelsummary(list(m1, m2), stars = TRUE, output = "table.docx")`
- **Stata**: `esttab m1 m2 using results.rtf, se star(* 0.10 ** 0.05 *** 0.01) r2 label` (`ssc install estout`); `outreg2` is an alternative

## 2. Interpretation -- show the workings
For each key coefficient:
1. **Sign and significance** -- direction, and the p-value / t-stat from output
2. **Units** -- what a one-unit change in X means for Y, given how each is measured
   - level-level: 1 unit X → beta units Y
   - log Y, level X: 1 unit X → approx. 100*beta % change in Y (exact: 100*(e^beta - 1)%)
   - level Y, log X: 1% change in X → beta/100 units Y
   - log-log: elasticity -- 1% change in X → beta % change in Y
3. **Economic magnitude** -- effect of a one-standard-deviation change in X: beta * SD(X), compared with the mean or SD of Y. Needs summary statistics: ask for them if absent
4. **Link back to the hypothesis** -- supported, not supported, or mixed

## 3. Paragraph template
"Table [N] reports [estimator] estimates of [Y] on [X]. The coefficient on [X] is [positive/negative] and statistically significant at the [__]% level (beta = __, t = __). Economically, a one-standard-deviation increase in [X] is associated with a [__] change in [Y], equivalent to [__]% of its sample mean. Standard errors are clustered by [level] (Petersen, 2009). The result is robust to [checks] (Columns [__]-[__])."

## 4. Methodology-section citations (Harvard) -- verify before use
Pull from the `regression-diagnostics`, `panel-data` and `event-study` skill reference lists. In-text form: (Petersen, 2009); two authors: (Fama and MacBeth, 1973); three or more: (Cameron *et al.*, 2011) -- follow your department's guide if it differs.

## 5. Checklist before the user submits
- [ ] Every number traceable to output
- [ ] SE type and clustering stated
- [ ] Economic, not just statistical, significance discussed
- [ ] Limitations stated (endogeneity, sample, proxies)
- [ ] Every reference checked against the original source
