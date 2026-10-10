---
name: event-study
description: Run a short-horizon event study -- market-model or factor-model abnormal returns, CARs, and cross-sectional significance tests (t-test, Patell/BMP standardised test, sign test) in Python, R or Stata. Use when the user studies stock-price reactions to announcements such as earnings, M&A, dividends, regulation or ratings changes.
argument-hint: "[python|r|stata] [event type and windows]"
---
# Event study

Default to **showing workings**. The design choices below are judgement calls -- **ask the user** for each one they have not specified, or state a clearly labelled **Assumption:**.

## 1. Design choices to confirm
| Choice | Common default (daily data) | Why it matters |
|---|---|---|
| Event date (day 0) | Announcement date; next trading day if after market close | Wrong day 0 dilutes the effect |
| Estimation window | [-250, -30] trading days (~1 year), min. ~100 valid returns | Must not overlap the event |
| Event window | [-1, +1] and [-5, +5]; also [0] | Captures leakage and delayed reaction |
| Benchmark model | Market model on a broad index | Alternatives: market-adjusted, Fama-French 3-factor, Carhart 4-factor |
| Market index | e.g. value-weighted local index | Must match the stocks' market |
| Confounding events | Exclude firms with other news in the window | Otherwise CAR mixes effects |

## 2. Workings (market model)
1. Estimate over the estimation window for each firm i: R_it = alpha_i + beta_i R_mt + e_it
2. Abnormal return in the event window: AR_it = R_it - (alpha_i_hat + beta_i_hat R_mt)
3. Cumulative abnormal return: CAR_i(t1, t2) = sum of AR_it from t1 to t2
4. Average across N firms: CAAR = (1/N) sum CAR_i
5. Test H0: CAAR = 0
   - **Cross-sectional t-test**: t = CAAR / (s_CAR / sqrt(N)) -- simple, robust to event-induced variance, but assumes independence across firms
   - **Patell (1976) standardised test**: standardises each AR by its estimation-period residual SD -- sensitive to event-induced variance
   - **BMP (Boehmer, Musumeci and Poulsen, 1991)**: standardised and robust to event-induced variance -- a common preferred choice
   - **Sign / rank test**: non-parametric robustness check
   - **Assumption flag:** if events cluster on the same calendar date (e.g. a regulation affecting all firms), cross-sectional independence fails -- use a portfolio approach or calendar-time method and tell the user.

## 3. Python (pandas + statsmodels)
```python
import numpy as np, pandas as pd
import statsmodels.api as sm
from scipy import stats

# returns: long DataFrame [firm_id, date, ret, mkt_ret], sorted by firm_id, date
# events:  DataFrame [firm_id, event_date]
EST = (-250, -30); EVT = (-1, 1); MIN_OBS = 100

rows = []
for _, ev in events.iterrows():
    r = returns[returns.firm_id == ev.firm_id].reset_index(drop=True)
    idx = r.index[r.date >= ev.event_date]
    if len(idx) == 0:
        continue
    t0 = idx[0]                                   # day 0 = first trading day on/after the event
    r["rel"] = r.index - t0                       # event time in trading days
    est = r[(r.rel >= EST[0]) & (r.rel <= EST[1])].dropna(subset=["ret", "mkt_ret"])
    evt = r[(r.rel >= EVT[0]) & (r.rel <= EVT[1])]
    if len(est) < MIN_OBS or len(evt) < EVT[1] - EVT[0] + 1:
        continue
    fit = sm.OLS(est.ret, sm.add_constant(est.mkt_ret)).fit()
    ar = evt.ret - (fit.params["const"] + fit.params["mkt_ret"] * evt.mkt_ret)
    sigma = np.sqrt(fit.mse_resid)
    L = len(evt)
    rows.append({"firm_id": ev.firm_id, "event_date": ev.event_date,
                 "CAR": ar.sum(), "SCAR": ar.sum() / (sigma * np.sqrt(L))})

res = pd.DataFrame(rows)
N = len(res)
caar = res.CAR.mean()
t_cs = caar / (res.CAR.std(ddof=1) / np.sqrt(N))                     # cross-sectional t
t_bmp = res.SCAR.mean() / (res.SCAR.std(ddof=1) / np.sqrt(N))        # BMP-style (simplified)
p_cs, p_bmp = 2 * stats.t.sf(abs(t_cs), N - 1), 2 * stats.t.sf(abs(t_bmp), N - 1)
pos_share = (res.CAR > 0).mean()                                     # input for a sign test
```
**Simplification note (tell the user):** the SCAR above standardises by the residual SD only; the full Patell/BMP standardisation also adjusts for forecast error in alpha and beta. For a dissertation, either use the full formula or cite a package that implements it (e.g. `estudy2` in R, `estudy` in Stata), and say which was used.

## 4. R
```r
# install.packages("estudy2")  -- implements market model, BMP, Patell, sign and rank tests
library(estudy2)
# See vignette("estudy2") for the full workflow: get_rates_from_prices() ->
# apply_market_model() -> parametric_tests() / nonparametric_tests()
```

## 5. Stata
```stata
* ssc install estudy  -- market model, multiple windows, Patell/BMP/sign tests
* Or build manually: for each event, regress ret mkt_ret in the estimation window,
* predict normal returns in the event window, generate ar = ret - normal, sum to CAR.
help estudy
```

## 6. Reporting
Table rows: event windows ([-1,+1], [-5,+5], [0]); columns: CAAR (%), t-stat (cross-sectional), BMP z/t, % positive, N. State estimation window, model and index in the table notes.

## References (Harvard) -- verify against the original before citing
- Boehmer, E., Musumeci, J. and Poulsen, A.B. (1991) 'Event-study methodology under conditions of event-induced variance', *Journal of Financial Economics*, 30(2), pp. 253-272.
- Brown, S.J. and Warner, J.B. (1985) 'Using daily stock returns: the case of event studies', *Journal of Financial Economics*, 14(1), pp. 3-31.
- Fama, E.F. and French, K.R. (1993) 'Common risk factors in the returns on stocks and bonds', *Journal of Financial Economics*, 33(1), pp. 3-56.
- MacKinlay, A.C. (1997) 'Event studies in economics and finance', *Journal of Economic Literature*, 35(1), pp. 13-39.
- Patell, J.M. (1976) 'Corporate forecasts of earnings per share and stock price behavior: empirical tests', *Journal of Accounting Research*, 14(2), pp. 246-276.
