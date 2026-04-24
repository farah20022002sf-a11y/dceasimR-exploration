# ============================================================
# 01_data_exploration.R
# Purpose: Explore and verify preloaded datasets in dceasimR
# Author: Farah AbuAmra
# Date: April 2026
# ============================================================

# ── 0. Load package ─────────────────────────────────────────

library(dceasimR)


# ── 1. Discover what datasets exist in the package ──────────

# This lists every dataset shipped with the package
data(package = "dceasimR")



# ── 2. Load each dataset into your environment ──────────────

# Run these one at a time. If a name doesn't exist,
# R will throw an error — that tells you the exact name
# is different. We'll correct from there.


data(england_imd_hale)
data(england_imd_qol)
data(example_cea_output)
data(nsclc_dcea_example)
data(who_regions_hale)
data(canada_income_hale)


# ============================================================
# SECTION A: BASELINE HEALTH DATASETS
# These are the population-level SES-stratified HALE data
# that form the inequality baseline in DCEA.
# ============================================================

# ── A1. Structure ────────────────────────────────────────────

str(england_imd_hale)
str(canada_income_hale)
str(who_regions_hale)


# ── A2. Full print (these should be small — 5 rows each) ────

print(england_imd_hale)
print(canada_income_hale)
print(who_regions_hale)


# ── A3. Summary statistics ───────────────────────────────────

summary(england_imd_hale)
summary(canada_income_hale)
summary(who_regions_hale)


# ── A4. Missing values ───────────────────────────────────────

colSums(is.na(england_imd_hale))
colSums(is.na(canada_income_hale))
colSums(is.na(who_regions_hale))


# ── A5. Duplicates ───────────────────────────────────────────

anyDuplicated(england_imd_hale)
anyDuplicated(canada_income_hale)
anyDuplicated(who_regions_hale)


# ── A6. Column data types ────────────────────────────────────

sapply(england_imd_hale, class)
sapply(canada_income_hale, class)
sapply(who_regions_hale, class)


# ── A7. Read documentation for each ─────────────────────────
# Run these one at a time — output appears in Help panel

?england_imd_hale
?canada_income_hale
?who_regions_hale


# ============================================================
# SECTION B: INEQUALITY GAP — ENGLAND IMD HALE
# ============================================================

# ── B1. Absolute gap (overall) ───────────────────────────────
# Most deprived vs least deprived

hale_max    <- max(england_imd_hale$mean_hale)
hale_min    <- min(england_imd_hale$mean_hale)
gap_overall <- hale_max - hale_min

cat("HALE gap (Q5 vs Q1, overall):",
    round(gap_overall, 2), "years\n")


# ── B2. Sex-disaggregated gaps ───────────────────────────────

gap_male <- max(england_imd_hale$mean_hale_male) -
  min(england_imd_hale$mean_hale_male)

gap_female <- max(england_imd_hale$mean_hale_female) -
  min(england_imd_hale$mean_hale_female)

cat("HALE gap (male):  ", round(gap_male,   2), "years\n")
cat("HALE gap (female):", round(gap_female, 2), "years\n")


# ── B3. Step-wise gradient ───────────────────────────────────
# How many HALE years separate each adjacent quintile?
# A consistent gradient = smooth socioeconomic gradient
# An irregular one = a specific group needs attention

gradient <- diff(england_imd_hale$mean_hale)

cat("\nHALE gain per quintile step (Q1→Q2, Q2→Q3, ...):\n")
print(round(gradient, 2))


# ── B4. Relative gap ─────────────────────────────────────────
# Absolute gap can be misleading if baseline HALE is low.
# Relative gap = what % less HALE does Q1 have vs Q5?

relative_gap <- (gap_overall / hale_max) * 100
cat("\nRelative gap (Q1 HALE as % below Q5):",
    round(relative_gap, 1), "%\n")


# ── B5. Uncertainty check ────────────────────────────────────
# Do the confidence intervals of adjacent quintiles overlap?
# If they do, the apparent gradient may not be statistically
# distinguishable — important caveat for any published work.
# Using ±1.96 * SE for approximate 95% CI

england_imd_hale$ci_lower <- england_imd_hale$mean_hale -
  1.96 * england_imd_hale$se_hale

england_imd_hale$ci_upper <- england_imd_hale$mean_hale +
  1.96 * england_imd_hale$se_hale

cat("\n95% Confidence Intervals by quintile:\n")
print(england_imd_hale[, c("quintile_label",
                           "mean_hale",
                           "ci_lower",
                           "ci_upper")])


# ── B6. Summary table for GitHub documentation ───────────────

inequality_summary <- data.frame(
  Metric  = c("Absolute gap (overall)",
              "Absolute gap (male)",
              "Absolute gap (female)",
              "Relative gap (%)",
              "Mean HALE (all quintiles)",
              "SE range"),
  Value   = c(round(gap_overall,  2),
              round(gap_male,     2),
              round(gap_female,   2),
              round(relative_gap, 1),
              round(mean(england_imd_hale$mean_hale), 2),
              paste0(min(england_imd_hale$se_hale),
                     " – ",
                     max(england_imd_hale$se_hale)))
)

print(inequality_summary)

# ============================================================
# SECTION C: VISUALIZATION — HALE BY IMD QUINTILE
# ============================================================

# Install ggplot2 if you don't have it yet
install.packages("ggplot2")

library(ggplot2)

# ── C1. Prepare plot data ────────────────────────────────────
# We'll use the version of the dataset that now includes
# ci_lower and ci_upper columns we calculated in D5.

plot_data <- england_imd_hale[, c("quintile_label",
                                  "mean_hale",
                                  "ci_lower",
                                  "ci_upper",
                                  "mean_hale_male",
                                  "mean_hale_female")]

# Set factor order so Q1 appears on the left
plot_data$quintile_label <- factor(
  plot_data$quintile_label,
  levels = c("Q1 (most deprived)", "Q2", "Q3",
             "Q4", "Q5 (least deprived)")
)


# ── C2. Main plot: Overall HALE with 95% CI ──────────────────

p1 <- ggplot(plot_data,
             aes(x = quintile_label, y = mean_hale)) +
  
  # Bars
  geom_col(fill = "#2c7bb6", width = 0.6, alpha = 0.85) +
  
  # Confidence interval error bars
  geom_errorbar(aes(ymin = ci_lower, ymax = ci_upper),
                width = 0.2, color = "black", linewidth = 0.7) +
  
  # Value labels on top of bars
  geom_text(aes(label = round(mean_hale, 1)),
            vjust = -1.8, size = 3.8, fontface = "bold") +
  
  # Start y-axis at 45 to better show variation
  coord_cartesian(ylim = c(45, 72)) +
  
  # Labels
  labs(
    title    = "Health-Adjusted Life Expectancy by\nDeprivation Quintile — England (2019)",
    subtitle = "IMD quintile | Q1 = most deprived | Error bars = 95% CI",
    x        = "IMD Quintile",
    y        = "Mean HALE (years)",
    caption  = "Source: PHE/OHID Health Profiles Plus (proxy estimates)\nData via dceasimR package"
  ) +
  
  theme_minimal(base_size = 12) +
  theme(
    plot.title    = element_text(face = "bold", size = 13),
    plot.subtitle = element_text(color = "grey40", size = 10),
    plot.caption  = element_text(color = "grey50", size = 8),
    axis.text.x   = element_text(size = 9),
    panel.grid.major.x = element_blank()
  )

print(p1)


# ── C3. Sex-disaggregated comparison ─────────────────────────
# Reshape to long format for grouped bars
install.packages("tidyr")
library(tidyr)

sex_data <- tidyr::pivot_longer(
  plot_data,
  cols      = c(mean_hale_male, mean_hale_female),
  names_to  = "sex",
  values_to = "hale"
)

# Clean up sex labels
sex_data$sex <- ifelse(sex_data$sex == "mean_hale_male",
                       "Male", "Female")

p2 <- ggplot(sex_data,
             aes(x = quintile_label, y = hale, fill = sex)) +
  
  geom_col(position = position_dodge(width = 0.7),
           width = 0.65, alpha = 0.85) +
  
  geom_text(aes(label = round(hale, 1)),
            position = position_dodge(width = 0.7),
            vjust = -0.5, size = 3.2) +
  
  coord_cartesian(ylim = c(45, 74)) +
  
  scale_fill_manual(values = c("Male"   = "#2c7bb6",
                               "Female" = "#d7191c")) +
  
  labs(
    title    = "HALE by Deprivation Quintile and Sex — England (2019)",
    subtitle = "IMD quintile | Q1 = most deprived",
    x        = "IMD Quintile",
    y        = "Mean HALE (years)",
    fill     = NULL,
    caption  = "Source: PHE/OHID Health Profiles Plus (proxy estimates)\nData via dceasimR package"
  ) +
  
  theme_minimal(base_size = 12) +
  theme(
    plot.title    = element_text(face = "bold", size = 13),
    plot.subtitle = element_text(color = "grey40", size = 10),
    plot.caption  = element_text(color = "grey50", size = 8),
    axis.text.x   = element_text(size = 9),
    panel.grid.major.x = element_blank(),
    legend.position = "top"
  )

print(p2)


# ── C4. Save both plots ──────────────────────────────────────
# Creates a /figures folder in your project directory

dir.create("figures", showWarnings = FALSE)

ggsave("figures/01_hale_by_quintile_overall.png",
       plot = p1, width = 8, height = 5.5, dpi = 300)

ggsave("figures/02_hale_by_quintile_sex.png",
       plot = p2, width = 9, height = 5.5, dpi = 300)

cat("Figures saved to /figures folder.\n")