---
name: panel-data
description: Estimate and justify panel-data models for finance research -- pooled OLS, fixed effects, random effects, Hausman test, clustered and double-clustered standard errors, and Fama-MacBeth regressions in Python, R or Stata. Use when the data has firms, funds or countries observed over time.
argument-hint: "[python|r|stata] [entity and time identifiers]"
---
# Panel data

Default to **showing workings**. Before writing code, confirm with the user: entity identifier (e.g. firm), time identifier (e.g. year), whether the panel is balanced, and the research question. These change the right estimator.

## 1. Choosing the estimator

| Model | Controls for | Use when | Key assumption |
|---|---|---|---|
| Pooled OLS | Nothing unobserved | Benchmark only | Unobserved firm traits uncorrelated with X |
| Entity fixed effects (within) | Time-invariant firm traits | Default in most corporate finance work | Strict exogeneity within firm; X must vary over time |
| Two-way FE (entity + time) | Firm traits + common shocks (e.g. market-wide years) | Macro shocks affect all firms | As above |
| Random effects | Assumes firm effect uncorrelated with X | Effects plausibly random; want time-invariant regressors | Cov(alpha_i, X) = 0 -- often rejected in finance |
| Fama-MacBeth | Cross-sectional correlation | Asset pricing: cross-section of returns each period | Corrects cross-sectional, **not** time-series, correlation |

**Hausman test**: H0 = RE is consistent (and efficient). Rejecting H0 favours FE. It must be run with **conventional (non-robust)** SEs; with clustered SEs use a robust alternative (e.g. Mundlak / auxiliary-regression approach, or `xtoverid` in Stata).

**Explain to the user**: FE removes anything constant within a firm, so a time-invariant variable (e.g. industry, if firms never switch) cannot be estimated with firm FE.

## 2. Standard errors in finance panels (Petersen, 2009)
- Firm effect (persistent within firm) → cluster by firm
- Time effect (common shocks across firms) → cluster by time, or add time FE
- Both → double cluster by firm and time (Cameron, Gelbach and Miller, 2011)
- **Assumption flag:** clustering needs enough clusters (a common rule of thumb is roughly 40-50+). With few time periods, clustering by time is unreliable -- tell the user.

## 3. Code

### Python (linearmodels)
```python
from linearmodels.panel import PanelOLS, RandomEffects, PooledOLS, FamaMacBeth, compare

pdf = df.set_index(["firm_id", "year"])          # entity first, time second

fe  = PanelOLS.from_formula("y ~ x1 + x2 + EntityEffects", data=pdf).fit(cov_type="clustered", cluster_entity=True)
twfe = PanelOLS.from_formula("y ~ x1 + x2 + EntityEffects + TimeEffects", data=pdf).fit(
    cov_type="clustered", cluster_entity=True, cluster_time=True)   # double clustered
re  = RandomEffects.from_formula("y ~ 1 + x1 + x2", data=pdf).fit()
fmb = FamaMacBeth.from_formula("y ~ 1 + x1 + x2", data=pdf).fit(cov_type="kernel")  # Newey-West-adjusted FMB SEs
print(compare({"FE": fe, "TWFE": twfe, "RE": re}))
```
`linearmodels` has no built-in Hausman test. Compute it manually from **non-robust** FE and RE fits:
```python
import numpy as np
from scipy import stats
fe_u = PanelOLS.from_formula("y ~ x1 + x2 + EntityEffects", data=pdf).fit()   # unadjusted SEs
re_u = RandomEffects.from_formula("y ~ 1 + x1 + x2", data=pdf).fit()
common = [c for c in fe_u.params.index if c in re_u.params.index]
b = fe_u.params[common] - re_u.params[common]
V = fe_u.cov.loc[common, common] - re_u.cov.loc[common, common]
H = float(b.T @ np.linalg.pinv(V) @ b)
p = stats.chi2.sf(H, len(common))
```
Note: V can be non-positive-definite in finite samples; if so, say so rather than reporting the statistic as reliable.

### R (fixest + plm)
```r
library(fixest); library(plm)

fe   <- feols(y ~ x1 + x2 | firm_id,        data = df, cluster = ~ firm_id)
twfe <- feols(y ~ x1 + x2 | firm_id + year, data = df, cluster = ~ firm_id + year)
etable(fe, twfe)

pdata <- pdata.frame(df, index = c("firm_id", "year"))
fe_p <- plm(y ~ x1 + x2, data = pdata, model = "within")
re_p <- plm(y ~ x1 + x2, data = pdata, model = "random")
phtest(fe_p, re_p)                                   # Hausman
fmb  <- pmg(y ~ x1 + x2, data = pdata, index = c("year", "firm_id"))  # Fama-MacBeth (time first)
```

### Stata
```stata
xtset firm_id year
xtreg y x1 x2, fe vce(cluster firm_id)

* Hausman (non-robust fits)
quietly xtreg y x1 x2, fe
estimates store fe
quietly xtreg y x1 x2, re
estimates store re
hausman fe re

* Two-way FE, double clustered (ssc install reghdfe, ftools)
reghdfe y x1 x2, absorb(firm_id year) vce(cluster firm_id year)

* Fama-MacBeth (ssc install asreg)
asreg y x1 x2, fmb newey(4)
```

## 4. Write-up template
"We estimate firm fixed-effects models with standard errors clustered by firm (Petersen, 2009). A Hausman test rejects the random-effects specification (chi2 = __, p = __) (Hausman, 1978)." Fill blanks only from actual output.

## References (Harvard) -- verify against the original before citing
- Cameron, A.C., Gelbach, J.B. and Miller, D.L. (2011) 'Robust inference with multiway clustering', *Journal of Business & Economic Statistics*, 29(2), pp. 238-249.
- Fama, E.F. and MacBeth, J.D. (1973) 'Risk, return, and equilibrium: empirical tests', *Journal of Political Economy*, 81(3), pp. 607-636.
- Hausman, J.A. (1978) 'Specification tests in econometrics', *Econometrica*, 46(6), pp. 1251-1271.
- Petersen, M.A. (2009) 'Estimating standard errors in finance panel data sets: comparing approaches', *Review of Financial Studies*, 22(1), pp. 435-480.
- Wooldridge, J.M. (2010) *Econometric analysis of cross section and panel data*. 2nd edn. Cambridge, MA: MIT Press.
