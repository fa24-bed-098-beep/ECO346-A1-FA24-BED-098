# 01_default.R -- Question 4: R's defaults, untouched
source("scripts/00_setup.R")
library(svglite)
p <- ggplot(lit, aes(age, literate)) + geom_point()
ggsave("figures/default.svg", p, width = 7, height = 4.5)
