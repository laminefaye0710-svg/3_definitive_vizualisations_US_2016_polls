# Definitive Visualizations of the 2016 US polls

---

## Overview

This script produces three definitive visualizations for the 2016 U.S. presidential election polling dataset. It builds directly on the work in [nmaccabe/polling-bias-2016-us-election](https://github.com/nmaccabe/polling-bias-2016-us-election), which found that weighting polls by pollster quality pushed aggregates *further* toward Clinton rather than correcting them toward Trump.

Nathan's repo explicitly lists three unresolved limitations. Each visualization here addresses one of them.

---

## Margin Convention

All margins follow Nathan's definition throughout:

```
margin = rawpoll_clinton - rawpoll_trump
```

Positive values = Clinton lead. Negative values = Trump lead. Units are raw percentage points.

---

## Data Sources

| Data | Source |
|------|--------|
| Poll data | `polls_us_election_2016.csv` (FiveThirtyEight via `dslabs`) |
| Certified results | `dslabs::results_us_election_2016` (Ballotpedia via rafalab/dslabs) |
| Pollster quality | `grade` column in poll data (FiveThirtyEight) |

The actual election results are loaded directly from `dslabs::results_us_election_2016` — nothing is hardcoded.

---

## Visualizations

### VIZ 1 — Polls vs Reality: 2016 Battleground Margins
![Polls vs Reality](output/figures/task3_viz1_predicted_vs_actual.png)
`output/figures/task3_viz1_predicted_vs_actual.png`

**Addresses:** Nathan had no ground truth comparison.

Each battleground state is plotted as poll average (y) against certified election result (x). Points above the y = x diagonal overestimated Clinton's lead. The Rust Belt states (MI, WI, PA) sit furthest above the line — the states that decided the Electoral College — while Florida and Nevada land close to it.

---

### VIZ 2 — LV Screen Inflated Clinton's Lead Among Quality Pollsters
`output/figures/task3_viz2_lv_rv_quality_gap.png`

**Addresses:** Nathan flagged LV screen quality as an unresolved limitation.

For each battleground state, shows the gap between the mean LV margin and the mean RV margin, faceted by pollster quality tier (B+ and above vs below B+). Among quality pollsters, the LV screen consistently gave Clinton a larger lead than the RV screen — the mechanism behind Nathan's finding that quality-weighted aggregates moved further toward Clinton.

---

### VIZ 3 — Late Polls Never Corrected Toward the True Result
`output/figures/task3_viz3_late_poll_convergence.png`

**Addresses:** Nathan flagged poll recency as an unresolved limitation.

A 14-day rolling mean poll average for each state that flipped to Trump, plotted against the certified result. In Michigan, Wisconsin, Pennsylvania, and New Hampshire the rolling average never converged to the true result through election eve, ruling out a late-campaign correction as an explanation for the miss.

---

## Repository Structure

```
├── R/
│   └── task3_definitive_visualizations.R
├── output/
│   └── figures/
│       ├── task3_viz1_predicted_vs_actual.png
│       ├── task3_viz2_lv_rv_quality_gap.png
│       └── task3_viz3_late_poll_convergence.png
├── data/
│   └── polls_us_election_2016.csv
└── README.md
```

---

## Dependencies

```r
library(tidyverse)
library(lubridate)
library(dslabs)
```

---

## References

- McCabe, N. *polling-bias-2016-us-election*. GitHub. https://github.com/nmaccabe/polling-bias-2016-us-election
- Irizarry, R.A. and Gill, A. (2021). `dslabs`: Data Science Labs. R package version 0.7.4.
- FiveThirtyEight. *How Our Pollster Ratings Work.* https://fivethirtyeight.com/methodology/how-our-pollster-ratings-work/
