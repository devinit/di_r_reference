list.of.packages <- c("data.table","ggplot2","scales")
new.packages <- list.of.packages[!(list.of.packages %in% installed.packages()[,"Package"])]
if(length(new.packages)) install.packages(new.packages)
lapply(list.of.packages, require, character.only=T)

reds = c(
  "#e84439", "#f8c1b2", "#f0826d", "#bc2629", "#8f1b13", "#fce3dc", "#fbd7cb", "#f6b0a0", "#ec6250", "#dc372d", "#cd2b2a", "#a21e25", "#6b120a"
)
oranges = c(
  "#eb642b", "#f6bb9d", "#f18e5e", "#d85b31", "#973915", "#fde5d4", "#fcdbbf", "#facbad", "#f3a47c", "#ee7644", "#cb5730", "#ac4622", "#7a2e05"
)
yellows = c(
  "#f49b21", "#fccc8e", "#f9b865", "#e48a00", "#a85d00", "#feedd4", "#fee7c1", "#fedcab", "#fac47e", "#f7a838", "#df8000", "#ba6b15", "#7d4712"
)
pinks = c(
  "#c2135b", "#e4819b", "#d64278", "#ad1257", "#7e1850", "#f9cdd0", "#f6b8c1", "#f3a5b6", "#e05c86", "#d12568", "#9f1459", "#8d0e56", "#65093d"
)
purples = c(
  "#893f90", "#c189bb", "#a45ea1", "#7b3b89", "#551f65", "#ebcfe5", "#deb5d6", "#cb98c4", "#af73ae", "#994d98", "#732c85", "#632572", "#42184c"
)
blues = c(
  "#0089cc", "#88bae5", "#5da3d9", "#0071b1", "#0c457b", "#d3e0f4", "#bcd4f0", "#a3c7eb", "#77adde", "#4397d3", "#105fa3", "#00538e", "#0a3a64"
)
greens = c(
  "#109e68", "#92cba9", "#5ab88a", "#1e8259", "#16513a", "#c5e1cb", "#b1d8bb", "#a2d1b0", "#74bf93", "#3b8c61", "#00694a", "#005b3e", "#07482e"
)
greys = c(
  "#6a6569", "#a9a6aa", "#847e84", "#555053", "#443e42", "#d9d4da", "#cac5cb", "#b3b0b7", "#b9b5bb", "#5a545a", "#736e73", "#4e484c", "#302b2e"
)

di_style = theme_bw() +
  theme(
    panel.border = element_blank()
    ,panel.grid.major.x = element_blank()
    ,panel.grid.minor.x = element_blank()
    ,panel.grid.major.y = element_line(colour = greys[2])
    ,panel.grid.minor.y = element_blank()
    ,panel.background = element_blank()
    ,plot.background = element_blank()
    ,axis.line.x = element_line(colour = "black")
    ,axis.line.y = element_blank()
    ,axis.ticks = element_blank()
    ,legend.position = "bottom"
  )

donut_style = di_style +
  theme(
    panel.grid.major.y = element_blank()
    ,axis.line.x = element_blank()
    ,axis.text = element_blank()
  )

rotate_x_text_45 = theme(
  axis.text.x = element_text(angle = 45, vjust = 1, hjust=1)
)
rotate_x_text_90 = theme(
  axis.text.x = element_text(angle = 90, vjust = 0.5, hjust=1)
)

test_data = data.frame(
  year = c(2000, 2000, 2001, 2001, 2002, 2002),
  type = c("ODA", "OOF", "ODA", "OOF", "ODA", "OOF"),
  value = runif(6)
)

# Bar
ggplot(test_data,aes(x=year,y=value,group=type,fill=type)) +
  geom_bar(stat="identity") +
  scale_fill_manual(values=reds) + # Choose colour here
  scale_y_continuous(expand = c(0, 0)) + # Force y-grid to start at x-axis
  di_style +
  rotate_x_text_45 + # Or chose _90 or remove for horizontal
  labs(
    y="US$ millions",
    x="",
    fill=""
  )

# Line
ggplot(test_data,aes(x=year,y=value,group=type,color=type)) +
  geom_line() +
  geom_point() + # Points on line
  scale_color_manual(values=greens) + # Choose colour here
  scale_y_continuous(expand = c(0, 0)) + # Force y-grid to start at x-axis
  expand_limits(y=c(0, max(test_data$value*1.1))) + # Start at 0 if wanted, add 10% padding to max
  scale_x_continuous(breaks=c(2000, 2001, 2002)) + # Set manually to avoid 2000.0
  di_style +
  labs(
    y="US$ millions",
    x="",
    color=""
  )

# Donut
donut_data = subset(test_data,year==2000)

donut_data$fraction = donut_data$value / sum(donut_data$value)
donut_data$ymax = cumsum(donut_data$fraction)
donut_data$ymin = c(0, head(donut_data$ymax, n=-1))
donut_data$yavg = (donut_data$ymin + donut_data$ymax) / 2

ggplot(donut_data, aes(ymax=ymax, ymin=ymin, xmax=4, xmin=3, fill=type)) +
  geom_rect() +
  geom_text(aes(label=percent(fraction), x=3.5, y=yavg)) +
  coord_polar(theta="y") + # Wrap y axis into polor coords
  xlim(c(2, 4)) +
  scale_fill_manual(values=purples) + # Choose colour here
  donut_style +
  labs(fill="",x="", y="")
