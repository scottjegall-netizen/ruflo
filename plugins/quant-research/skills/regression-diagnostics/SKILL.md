---
name: regression-diagnostics
description: Test OLS assumptions and choose correct standard errors in Python, R or Stata. Use when the user runs a linear regression and asks about heteroskedasticity, autocorrelation, multicollinearity, functional form, robust or Newey-West standard errors, or whether their regression is "valid".
argument-hint: "[python|r|stata] [description of model]"
---
# Regression diagnostics (OLS)

Default to **showing workings**: explain what each test checks, its null hypothesis, and how to read the result. Give code in the user's tool. Never invent test results -- run the code on their data or describe what the output will show.

## 1. What OLS needs, and what breaks if it fails

| Assumption | If violated | Consequence |
|---|---|---|
| Linear in parameters, correct functional form | Omitted non-linearity | Biased coefficients |
| Exogeneity, E[u given X] = 0 | Omitted variables, reverse causality, measurement error | **Biased and inconsistent** -- tests below do not fix this |
| No perfect multicollinearity | Exact linear dependence | Model cannot be estimated |
| Homoskedasticity | Var(u) changes with X | Coefficients fine, **standard errors wrong** |
| No autocorrelation | Errors correlated over time | Coefficients fine, **standard errors wrong** |
| Normal errors | Non-normal | Matters mainly in small samples |

Key point to stress: heteroskedasticity and autocorrelation affect **inference** (SEs, t-stats), not the point estimates. Endogeneity affects the estimates themselves and needs a design fix (controls, fixed effects, IV), not a different SE.

## 2. Tests

| Problem | Test | H0 | Reject H0 means |
|---|---|---|---|
| Heteroskedasticity | Breusch-Pagan; White | Homoskedastic errors | Use robust (HC) SEs |
| Autocorrelation (time series) | Breusch-Godfrey (lags p); Durbin-Watson (AR(1) only, no lagged y) | No serial correlation | Use HAC (Newey-West) SEs or model the dynamics |
| Multicollinearity | VIF (rule of thumb: > 10 concerning) | -- (descriptive) | Imprecise estimates; consider dropping/combining regressors |
| Functional form | Ramsey RESET | Correct functional form | Consider logs, squares, interactions |
| Normality | Jarque-Bera | Normal residuals | Mostly relevant in small samples |

**Assumption flag:** the lag length for Breusch-Godfrey / Newey-West is a choice. A common rule of thumb is floor(4(T/100)^(2/9)) (Newey and West, 1994), but state whichever rule is used.

## 3. Code

### Python (statsmodels)
```python
import statsmodels.formula.api as smf
import statsmodels.api as sm
from statsmodels.stats.diagnostic import het_breuschpagan, het_white, acorr_breusch_godfrey, linear_reset
from statsmodels.stats.outliers_influence import variance_inflation_factor

res = smf.ols("y ~ x1 + x2 + x3", data=df).fit()
print(res.summary())

# Heteroskedasticity
bp_lm, bp_p, _, _ = het_breuschpagan(res.resid, res.model.exog)
w_lm, w_p, _, _ = het_white(res.resid, res.model.exog)
# Autocorrelation (time-series data, sorted by date)
bg_lm, bg_p, _, _ = acorr_breusch_godfrey(res, nlags=4)
# Functional form
reset = linear_reset(res, power=3, use_f=True)
# Multicollinearity
X = res.model.exog
vif = {name: variance_inflation_factor(X, i) for i, name in enumerate(res.model.exog_names) if name != "Intercept"}

# Robust standard errors
res_hc = smf.ols("y ~ x1 + x2 + x3", data=df).fit(cov_type="HC1")                           # heteroskedasticity-robust
res_nw = smf.ols("y ~ x1 + x2 + x3", data=df).fit(cov_type="HAC", cov_kwds={"maxlags": 4})  # Newey-West
res_cl = smf.ols("y ~ x1 + x2 + x3", data=df).fit(cov_type="cluster", cov_kwds={"groups": df["firm_id"]})
```
Note: `cov_type="cluster"` needs no missing values in the regression variables or the group column -- drop NaNs first so rows align.

### R
```r
library(lmtest); library(sandwich); library(car)

m <- lm(y ~ x1 + x2 + x3, data = df)
summary(m)

bptest(m)                                   # Breusch-Pagan
bptest(m, ~ x1 * x2 + I(x1^2) + I(x2^2))    # White-style (spell out the terms)
bgtest(m, order = 4)                        # Breusch-Godfrey
resettest(m, power = 2:3)                   # RESET
vif(m)                                      # VIF

coeftest(m, vcov = vcovHC(m, type = "HC1"))              # robust
coeftest(m, vcov = NeweyWest(m, lag = 4, prewhite = FALSE)) # Newey-West
coeftest(m, vcov = vcovCL(m, cluster = ~ firm_id))       # clustered
```

### Stata
```stata
regress y x1 x2 x3
estat hettest            // Breusch-Pagan
estat imtest, white      // White
estat ovtest             // RESET
estat vif

regress y x1 x2 x3, vce(robust)            // robust SEs
regress y x1 x2 x3, vce(cluster firm_id)   // clustered SEs

* Time series: declare time first
tsset date
regress y x1 x2 x3
estat bgodfrey, lags(4)  // Breusch-Godfrey
newey y x1 x2 x3, lag(4) // Newey-West SEs
```

## 4. Reading the results -- template
"The Breusch-Pagan test rejects homoskedasticity (LM = __, p = __), so inference uses heteroskedasticity-robust standard errors (White, 1980)." Fill blanks only with numbers from the user's actual output.

## 5. Decision guide for standard errors
- Cross-section, independent observations → HC (robust)
- Single time series → HAC / Newey-West
- Panel (firms over time) → clustered; see the `panel-data` skill
- When in doubt in finance panels, report firm-clustered SEs and show robustness to double clustering (Petersen, 2009)

## References (Harvard) -- verify against the original before citing
- Breusch, T.S. and Pagan, A.R. (1979) 'A simple test for heteroscedasticity and random coefficient variation', *Econometrica*, 47(5), pp. 1287-1294.
- Newey, W.K. and West, K.D. (1987) 'A simple, positive semi-definite, heteroskedasticity and autocorrelation consistent covariance matrix', *Econometrica*, 55(3), pp. 703-708.
- Newey, W.K. and West, K.D. (1994) 'Automatic lag selection in covariance matrix estimation', *Review of Economic Studies*, 61(4), pp. 631-653.
- Petersen, M.A. (2009) 'Estimating standard errors in finance panel data sets: comparing approaches', *Review of Financial Studies*, 22(1), pp. 435-480.
- White, H. (1980) 'A heteroskedasticity-consistent covariance matrix estimator and a direct test for heteroskedasticity', *Econometrica*, 48(4), pp. 817-838.
