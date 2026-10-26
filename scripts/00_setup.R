# 00_setup.R -- shared by every R script. Run from the repository root.
# Variant 2 (FA24-BEDS-098: 98 = 12*8 + 2) = Sindh (prov_code 3), rural (urban_rural 1)
suppressPackageStartupMessages({ library(dplyr); library(readr); library(ggplot2); library(scales) })
PROV <- 3; AREA <- 1
for (f in c("figures", "tables")) dir.create(f, showWarnings = FALSE)

persons <- read_csv("data/pslm_person_subset.csv", show_col_types = FALSE)
hh      <- read_csv("data/pslm_hh_subset.csv", show_col_types = FALSE) |>
  select(hhid, hhweight, prov_code, urban_rural)

# attach weight, province, area by hhid; keep only my variant
d <- persons |> inner_join(hh, by = "hhid") |> filter(prov_code == PROV, urban_rural == AREA)

# weighted quantile, exactly as defined in the assignment:
# sort by x, cumulative share of weight, smallest x whose share >= p
wquant <- function(x, w, p) {
  o <- order(x); x <- x[o]; w <- w[o]
  x[which(cumsum(w) / sum(w) >= p - 1e-12)[1]]
}

# literacy sample: age 10-64, literate not missing
lit <- d |>
  filter(age >= 10, age <= 64, !is.na(literate)) |>
  mutate(band_start = 5 * (age %/% 5),
         mid  = band_start + 2,
         band = paste0(band_start, "-", band_start + 4),
         sex_lab = factor(sex, levels = c(1, 2), labels = c("Men", "Women")))

# students: ed_total > 0
students <- d |> filter(!is.na(ed_total), ed_total > 0)

# break long titles/captions into lines so they do not run off the figure
wrap <- function(x, width = 100) paste(strwrap(x, width = width), collapse = "\n")