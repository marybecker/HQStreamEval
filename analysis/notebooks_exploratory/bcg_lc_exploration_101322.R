library(ggplot2)

bcg_lc <- read.csv("analysis/data/raw/bcg_lc_042922.csv",header = TRUE)

ggplot(bcg_lc, aes(as.factor(hq),coreforest)) +
  geom_boxplot()

ggplot(bcg_lc, aes(as.factor(lcYr),levPropNum)) +
  geom_boxplot()

kruskal.test(sum_strdrf_pct ~ hq, data = bcg_lc)

cor(bcg_lc[complete.cases(bcg_lc),13:24], method = "kendall")

cor(bcg_lc[complete.cases(bcg_lc),13:24],
    bcg_lc[complete.cases(bcg_lc),9], method = "kendall")

ggplot(bcg_lc, aes(as.factor(lcYr),levPropNum)) +
  geom_boxplot()

ggplot(bcg_lc, aes(as.factor(lev1Name), coreforest)) +
  geom_boxplot()+
  # scale_y_log10()+
  xlab('BCG') +
  ylab('Percent Core Forest') +
  theme(panel.background = element_rect(fill = '#252525', colour = '#969696'),
        plot.background = element_rect(fill = '#252525'),
        panel.grid = element_blank(),
        axis.text = element_text(colour = '#cccccc',size=rel(1.1)),
        axis.title = element_text(color = '#cccccc',size=rel(1.1)),
        title = element_text(color = '#cccccc',size=rel(1.5)),
        legend.position = 'none')