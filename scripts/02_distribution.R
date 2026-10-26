# 02_distribution.R -- Question 2: weighted log-scale histogram of education spending
source("scripts/00_setup.R")
library(svglite)

n_students <- nrow(students)
w_med   <- wquant(students$ed_total, students$hhweight, 0.5)
u_med   <- median(students$ed_total)               # unweighted
p10     <- wquant(students$ed_total, students$hhweight, 0.1)
p90     <- wquant(students$ed_total, students$hhweight, 0.9)

s <- students |> mutate(lx = log10(ed_total))
inside <- s |> filter(lx >= 2, lx <= 6)
n_excl <- n_students - nrow(inside)

cat(sprintf("students=%d | weighted median=%s | unweighted median=%s | p10=%s | p90=%s | ratio=%.2f | excluded=%d\n",
            n_students, w_med, u_med, p10, p90, p90 / p10, n_excl))
writeLines(sprintf("students=%d\nweighted_median=%s\nunweighted_median=%s\np10=%s\np90=%s\nratio=%.2f\nexcluded=%d",
                   n_students, w_med, u_med, p10, p90, p90 / p10, n_excl), "tables/q2_numbers.txt")

p <- ggplot(inside, aes(x = lx, weight = hhweight)) +
  geom_histogram(aes(y = after_stat(density)), binwidth = 0.1, boundary = 2,
                 closed = "left", fill = "grey70", colour = "white") +
  geom_vline(xintercept = log10(c(w_med, p90)), linetype = "dashed") +
  annotate("text", x = log10(w_med), y = Inf, vjust = 1.5, hjust = 1.08,
           label = paste0("Weighted median\nRs ", comma(w_med))) +
  annotate("text", x = log10(p90), y = Inf, vjust = 1.5, hjust = -0.08,
           label = paste0("90th percentile\nRs ", comma(p90))) +
  scale_x_continuous(breaks = 2:6, limits = c(2, 6),
                     labels = c("Rs 100", "Rs 1,000", "Rs 10,000", "Rs 100,000", "Rs 1,000,000")) +
  labs(title = wrap(paste0("Rural Sindh households spend about Rs ", comma(w_med),
                           " a year on a typical student; one in ten spends Rs ", comma(p90), " or more"), 80),
       x = "Annual education spending per student (log scale)",
       y = "Density per log10 unit",
       caption = wrap(paste0("Source: PSLM 2019-20, person and household files. Sample: ", comma(n_students),
                             " students (ed_total > 0) in rural Sindh; ", n_excl,
                             " outside Rs 100-1,000,000 excluded. Weighted by hhweight; bins 0.1 wide in log10."), 120)) +
  theme_minimal(base_size = 12) +
  theme(panel.grid.minor = element_blank(), plot.title = element_text(face = "bold", size = 12),
        plot.title.position = "plot", plot.caption = element_text(hjust = 0, size = 8),
        plot.caption.position = "plot")
ggsave("figures/distribution.svg", p, width = 9, height = 5.5)