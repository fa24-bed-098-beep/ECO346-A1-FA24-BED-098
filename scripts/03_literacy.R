# 03_literacy.R -- Question 3 (and the redesign for Question 4)
source("scripts/00_setup.R")
library(svglite)

tab <- lit |>
  group_by(mid, band, sex_lab) |>
  summarise(n = n(), rate = 100 * sum(hhweight * literate) / sum(hhweight), .groups = "drop") |>
  mutate(thin = n < 30)
write_csv(tab, "tables/band_table_R.csv")

wide <- tab |> select(mid, band, sex_lab, n, rate) |>
  tidyr::pivot_wider(names_from = sex_lab, values_from = c(n, rate)) |>
  mutate(gap = rate_Men - rate_Women)
cat("\nBand table (percent literate):\n"); print(wide |> mutate(across(starts_with("rate"), \(x) round(x, 1)), gap = round(gap, 1)), n = Inf)

# markdown table for the README
md <- c("| Band | Men n | Men literate % | Women n | Women literate % |", "|---|---|---|---|---|",
        sprintf("| %s | %d | %.1f | %d | %.1f |", wide$band, wide$n_Men, wide$rate_Men, wide$n_Women, wide$rate_Women))
writeLines(md, "tables/band_table.md")

g <- wide |> slice_max(abs(gap), n = 1)
r <- function(b, s) round(tab$rate[tab$band == b & tab$sex_lab == s], 1)
cat(sprintf("\n15-19: women %.1f men %.1f | 55-59: women %.1f men %.1f | largest gap band %s (%.1f points)\n",
            r("15-19","Women"), r("15-19","Men"), r("55-59","Women"), r("55-59","Men"), g$band, g$gap))

cols <- c(Women = "#C0392B", Men = "#1F5A99")
ends <- tab |> filter(mid == max(mid))
p <- ggplot(tab, aes(mid, rate, colour = sex_lab, group = sex_lab)) +
  geom_line(linewidth = 0.8) +
  geom_point(aes(shape = thin), size = 3, stroke = 1.1) +
  scale_shape_manual(values = c(`FALSE` = 16, `TRUE` = 1)) +
  geom_segment(data = g, aes(x = mid, xend = mid, y = rate_Women, yend = rate_Men),
               inherit.aes = FALSE, colour = "black", linetype = "dotted") +
  annotate("text", x = g$mid + 1, y = (g$rate_Men + g$rate_Women) / 2, hjust = 0, colour = "black",
           label = sprintf("Largest gap: %.1f points\n(ages %s)", g$gap, g$band)) +
  geom_text(data = ends, aes(label = sex_lab), hjust = -0.25, fontface = "bold") +
  scale_colour_manual(values = cols) +
  scale_x_continuous(breaks = seq(12, 62, 5)) +
  scale_y_continuous(limits = c(0, 100), labels = \(x) paste0(x, "%")) +
  coord_cartesian(clip = "off") +
  labs(title = sprintf("In rural Sindh men are more literate than women at every age, by up to %.1f points", g$gap),
       x = "Age band (plotted at midpoint, years)", y = "Literate (weighted share)",
       caption = wrap(paste0("Source: PSLM 2019-20, person and household files. Sample: persons aged 10-64 in rural Sindh with literate observed (n = ",
                             comma(nrow(lit)), "). Weighted by hhweight. Hollow markers: fewer than 30 observations in that band for that sex."), 120)) +
  theme_minimal(base_size = 12) +
  theme(legend.position = "none", panel.grid.minor = element_blank(),
        plot.title = element_text(face = "bold", size = 12), plot.title.position = "plot",
        plot.caption = element_text(hjust = 0, size = 8), plot.caption.position = "plot",
        plot.margin = margin(8, 50, 8, 8))
ggsave("figures/literacy_by_age.svg", p, width = 9, height = 5.5)