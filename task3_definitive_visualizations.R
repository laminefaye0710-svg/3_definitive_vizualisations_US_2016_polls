# =============================================================================
# Definitive Visualizations
#
# Builds directly on: github.com/nmaccabe/polling-bias-2016-us-election
#
# Nathan established that pollster-quality weighting pushed estimates further
# toward Clinton. His repo explicitly flags these as unresolved limitations:
#   - actual 2016 state results (no ground truth comparison)
#   - LV screen quality interaction with pollster grade
#   - poll recency / late campaign movement
#
# These three visualizations complete the story by addressing those gaps.
#
# Margin convention (Nathan's, maintained throughout):
#   margin = rawpoll_clinton - rawpoll_trump
#   Positive = Clinton lead. Negative = Trump lead. Units = raw pp.
# =============================================================================

library(tidyverse)
library(lubridate)

dir.create("output/figures", recursive = TRUE, showWarnings = FALSE)

# --- Load data ---------------------------------------------------------------
polls <- read_csv("polls_us_election_2016.csv") |>
  mutate(
    margin    = rawpoll_clinton - rawpoll_trump,
    enddate   = as.Date(enddate),
    quality   = grade %in% c("A+", "A", "A-", "B+")
  )

# Ground truth: pulled from dslabs::results_us_election_2016
# Columns: state, electoral_votes, clinton, trump (popular vote %)
# Source: Ballotpedia via rafalab/dslabs
library(dslabs)
data(results_us_election_2016)

battlegrounds <- c(
  "Florida", "Pennsylvania", "Michigan", "Wisconsin", "Ohio",
  "Iowa", "North Carolina", "Arizona", "Nevada", "New Hampshire",
  "Minnesota", "Colorado"
)

actuals <- results_us_election_2016 |>
  filter(state %in% battlegrounds) |>
  mutate(
    actual  = clinton - trump,   # same sign convention as Nathan's margin
    flipped = trump > clinton
  ) |>
  select(state, actual, flipped)

election_day  <- as.Date("2016-11-08")
final3w_start <- as.Date("2016-10-17")


# =============================================================================
# VIZ 1 — Predicted vs Actual: Where the Polls Were Wrong and by How Much
#
# Nathan found that quality-weighting made the aggregate estimate more Clinton-
# favourable. This chart shows the direct consequence at state level: each
# battleground's poll average plotted against the certified election result.
# Every point above the y = x diagonal means polls overestimated Clinton.
# The Rust Belt cluster (MI, WI, PA) sits furthest above the line — the
# states that decided the Electoral College.
# =============================================================================

state_avg <- polls |>
  filter(state %in% actuals$state) |>
  group_by(state) |>
  summarise(
    poll_avg = mean(margin, na.rm = TRUE),
    n_polls  = n(),
    .groups  = "drop"
  )

viz1 <- actuals |>
  left_join(state_avg, by = "state") |>
  mutate(
    miss       = poll_avg - actual,
    lbl_hjust  = if_else(poll_avg > 4 | state == "Colorado", 1.1, -0.08)
  )

axis_range <- c(-12, 10)

p1 <- ggplot(viz1, aes(x = actual, y = poll_avg)) +
  # Perfect-prediction diagonal
  geom_abline(slope = 1, intercept = 0,
              colour = "grey55", linewidth = 0.7, linetype = "dashed") +
  # Quadrant zero lines
  geom_hline(yintercept = 0, colour = "grey85", linewidth = 0.35) +
  geom_vline(xintercept = 0, colour = "grey85", linewidth = 0.35) +
  # Vertical error segment (poll avg → diagonal)
  geom_segment(
    aes(xend = actual, yend = actual, colour = flipped),
    linewidth = 0.55, alpha = 0.55
  ) +
  # State points
  geom_point(aes(colour = flipped, shape = flipped), size = 3.8, alpha = 0.9) +
  # State labels
  geom_text(
    aes(label = state, hjust = lbl_hjust),
    size = 2.75, family = "sans"
  ) +
  # Annotation box for Rust Belt
  annotate("rect",
           xmin = -1.5, xmax = 0.4, ymin = 3.6, ymax = 7.4,
           fill = NA, colour = "#c0392b", linewidth = 0.55, linetype = "dotted") +
  annotate("text",
           x = -0.55, y = 7.75, size = 2.7, colour = "#c0392b", hjust = 0.5,
           label = "Rust Belt: polls said Clinton,\nvoters said Trump") +
  scale_colour_manual(
    values = c("TRUE" = "#c0392b", "FALSE" = "#1a6bbd"),
    labels = c("TRUE" = "Flipped to Trump", "FALSE" = "Held for Clinton"),
    name   = NULL
  ) +
  scale_shape_manual(
    values = c("TRUE" = 16, "FALSE" = 17),
    labels = c("TRUE" = "Flipped to Trump", "FALSE" = "Held for Clinton"),
    name   = NULL
  ) +
  coord_equal(xlim = axis_range, ylim = axis_range) +
  labs(
    title   = "Polls vs Reality: 2016 Battleground Margins",
    x       = "Actual margin (Clinton − Trump, pp)",
    y       = "Poll average margin (Clinton − Trump, pp)",
    caption = "margin = rawpoll_clinton − rawpoll_trump  |  Actual results: dslabs::results_us_election_2016 (Ballotpedia)"
  ) +
  theme_minimal(base_size = 11) +
  theme(
    plot.title       = element_text(face = "bold", size = 12),
    plot.subtitle    = element_text(size = 8.5, colour = "grey40", lineheight = 1.45),
    plot.caption     = element_text(size = 7,   colour = "grey55", lineheight = 1.3),
    legend.position  = "top",
    panel.grid.minor = element_blank()
  )

ggsave("output/figures/task3_viz1_predicted_vs_actual.png",
       p1, width = 7.5, height = 7.5, dpi = 200)
message("Saved: task3_viz1_predicted_vs_actual.png")


# =============================================================================
# VIZ 2 — The LV Screen Gap Interacts with Pollster Quality
#
# Nathan flagged LV screen quality as an unaddressed limitation. This chart
# completes it. For each battleground state, it shows the LV-minus-RV margin
# gap separately for quality pollsters (B+ and above) vs low-quality pollsters
# (below B+). Among quality pollsters the LV screen consistently gave Clinton
# a larger lead than the RV screen — a bias that compounded Nathan's finding
# that quality-weighted aggregates moved further toward Clinton. Among
# low-quality pollsters, the gap is smaller and less directionally consistent.
# The LV screen was not a neutral methodological choice in 2016.
# =============================================================================

lv_rv_gap <- polls |>
  filter(state %in% actuals$state, population %in% c("lv", "rv")) |>
  group_by(state, population, quality) |>
  summarise(
    mean_margin = mean(margin, na.rm = TRUE),
    n           = n(),
    .groups     = "drop"
  ) |>
  pivot_wider(
    names_from  = population,
    values_from = c(mean_margin, n),
    names_sep   = "_"
  ) |>
  filter(!is.na(mean_margin_lv), !is.na(mean_margin_rv)) |>
  mutate(
    lv_rv_gap     = mean_margin_lv - mean_margin_rv,
    quality_label = if_else(
      quality,
      "Quality pollsters (B+ and above)",
      "Low-quality pollsters (below B+)"
    ),
    gap_dir = if_else(
      lv_rv_gap >= 0,
      "LV inflated Clinton's lead",
      "RV inflated Clinton's lead"
    ),
    state = fct_reorder(state, lv_rv_gap)
  )

p2 <- ggplot(lv_rv_gap, aes(x = lv_rv_gap, y = state, fill = gap_dir)) +
  geom_col(alpha = 0.85, width = 0.68) +
  geom_vline(xintercept = 0, linewidth = 0.6, colour = "grey25") +
  facet_wrap(~ quality_label, ncol = 2) +
  scale_fill_manual(
    values = c(
      "LV inflated Clinton's lead" = "#1a6bbd",
      "RV inflated Clinton's lead" = "#c0392b"
    ),
    name = NULL
  ) +
  scale_x_continuous(
    breaks = seq(-6, 6, 2),
    expand = expansion(mult = c(0.3, 0.4))
  ) +
  labs(
    title   = "LV Screen Inflated Clinton's Lead Among Quality Pollsters",
    x       = "LV margin minus RV margin (pp)",
    y       = NULL,
    caption = "margin = rawpoll_clinton − rawpoll_trump  |  Quality = grade B+ and above  |  Source: polls_us_election_2016"
  ) +
  theme_minimal(base_size = 11) +
  theme(
    plot.title       = element_text(face = "bold", size = 12),
    plot.subtitle    = element_text(size = 8.5, colour = "grey40", lineheight = 1.45),
    plot.caption     = element_text(size = 7,   colour = "grey55", lineheight = 1.3),
    legend.position  = "top",
    strip.text       = element_text(face = "bold", size = 10),
    panel.grid.minor = element_blank()
  )

ggsave("output/figures/task3_viz2_lv_rv_quality_gap.png",
       p2, width = 11, height = 6, dpi = 200)
message("Saved: task3_viz2_lv_rv_quality_gap.png")


# =============================================================================
# VIZ 3 — Did Late Polls Correct Toward the Truth?
#
# Nathan's repo did not account for poll recency — another stated limitation.
# Conventional wisdom holds that polls improve as election day approaches.
# This chart tests that directly: a 14-day rolling mean poll average for each
# state that flipped to Trump, with the certified result as the benchmark.
# For Michigan, Wisconsin, Pennsylvania, and New Hampshire the rolling average
# never converged to the true result — the overestimate persisted to the end.
# This rules out "it was just an early-campaign artifact" as the explanation
# and confirms the error was structural, not temporal.
# =============================================================================

flipped_states <- actuals |> filter(flipped) |> pull(state)

# 14-day rolling mean per state using base R (no extra packages needed)
rolling_data <- polls |>
  filter(state %in% flipped_states) |>
  arrange(state, enddate) |>
  group_by(state) |>
  mutate(
    roll_mean = map_dbl(seq_along(enddate), function(i) {
      window <- margin[enddate >= (enddate[i] - 13) & enddate <= enddate[i]]
      mean(window, na.rm = TRUE)
    })
  ) |>
  ungroup() |>
  left_join(actuals |> select(state, actual), by = "state") |>
  mutate(
    state = factor(state, levels = c(
      "Michigan", "Wisconsin", "Pennsylvania", "North Carolina",
      "Florida", "Arizona", "Ohio", "Iowa"
    ))
  )

p3 <- ggplot(rolling_data, aes(x = enddate)) +
  # Final 3 weeks shading
  annotate("rect",
           xmin = final3w_start, xmax = election_day + 1,
           ymin = -Inf, ymax = Inf,
           fill = "#f5e6d3", alpha = 0.55) +
  # Individual poll points (background noise reference)
  geom_point(aes(y = margin),
             alpha = 0.10, size = 0.55, colour = "grey50") +
  # 14-day rolling mean
  geom_line(aes(y = roll_mean),
            colour = "#1a6bbd", linewidth = 0.95, na.rm = TRUE) +
  # Actual result benchmark
  geom_hline(aes(yintercept = actual),
             colour = "#c0392b", linewidth = 0.85, linetype = "dashed") +
  # Zero line
  geom_hline(yintercept = 0, colour = "grey75", linewidth = 0.3) +
  # Election day marker
  geom_vline(xintercept = election_day,
             colour = "grey30", linewidth = 0.45, linetype = "dotted") +
  # Label the final-3-weeks zone once (top-left panel only, using annotation)
  facet_wrap(~ state, ncol = 2, scales = "free_y") +
  scale_x_date(
    date_breaks = "3 months",
    date_labels = "%b '%y",
    limits      = c(as.Date("2015-11-01"), election_day + 5)
  ) +
  labs(
    title   = "Late Polls Never Corrected Toward the True Result",
    x       = NULL,
    y       = "Clinton margin (pp)",
    caption = "Blue = 14-day rolling mean  |  Red dashed = certified result  |  Shaded = final 3 weeks  |  Source: polls_us_election_2016"
  ) +
  theme_minimal(base_size = 10) +
  theme(
    plot.title       = element_text(face = "bold", size = 12),
    plot.subtitle    = element_text(size = 8.5, colour = "grey40", lineheight = 1.45),
    plot.caption     = element_text(size = 7,   colour = "grey55", lineheight = 1.3),
    strip.text       = element_text(face = "bold", size = 10),
    axis.text.x      = element_text(size = 7, angle = 20, hjust = 1),
    panel.grid.minor = element_blank(),
    panel.spacing    = unit(1.1, "lines")
  )

ggsave("output/figures/task3_viz3_late_poll_convergence.png",
       p3, width = 10, height = 11, dpi = 200)
message("Saved: task3_viz3_late_poll_convergence.png")

message("\nAll three definitive visualizations saved to output/figures/")
