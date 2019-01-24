list.of.packages <- c("data.table","WDI","ggplot2","reshape2","scales")
new.packages <- list.of.packages[!(list.of.packages %in% installed.packages()[,"Package"])]
if(length(new.packages)) install.packages(new.packages)
lapply(list.of.packages, require, character.only=T)

# As with module 3, let's grab some test data from the WDI.
dat = WDI(indicator=c("NY.GDP.MKTP.KD","SP.POP.TOTL"),country="GB",start=1960,end=2018)
# Quickly calculate GDP per capita again
dat$gdp_per_cap = dat$NY.GDP.MKTP.KD/dat$SP.POP.TOTL

# R comes with some default options for creating charts. Namely `plot` and a few others.
plot(y=dat$gdp_per_cap,x=dat$year)

# By default, it's a scatter plot. You can also make it a line
plot(y=dat$gdp_per_cap,x=dat$year,type="l")

# And you can also use function notation `y~x` if you specify the `data` argument
plot(gdp_per_cap~year,data=dat,type="l")

# But these charts are ugly and boring. Let me introduce you to ggplot2!
ggplot(dat,aes(x=year,y=gdp_per_cap)) +
  geom_line() +
  scale_y_continuous(labels=dollar) +
  theme_bw() +
  labs(x="Year",y="GDP per capita (constant 2010 $)",title="UK GDP per capita over time")

# ggplot2 is additive, meaning you can start with your default configuration and add details later
config = ggplot(dat,aes(x=year,y=gdp_per_cap))
config + geom_line()
config + geom_point()
config + geom_smooth(method="loess")

# It's also useful for making quite complicated charts. Let's say we want to all variables on the same chart (with log scale)
dat_melt = melt(dat,id.vars=c("iso2c","country","year"))
ggplot(dat_melt,aes(x=year,y=value,colour=variable,group=variable)) +
  geom_line() +
  scale_y_log10()

# Here's an example of a DI style chart I coded for the GNR report
# Make sure to edit the working directory before loading the data
setwd("~/git/di_r_reference")
countrydat = read.csv("data/Zimbabwe_GNR.csv",na.strings="",as.is=T)

indicators = c("ODA_received","ODA_specific")
c29names = c("% of total ODA","Basic nutrition ODA received")
y.lab = "ODA, US$ millions"

# First some data manipulation
c29data = subset(countrydat,indicator %in% indicators)
c29data$value = as.numeric(c29data$value)
c29data$value[which(c29data$indicator==indicators[1])] = c29data$value[which(c29data$indicator==indicators[1])] * 100
c29data = subset(c29data, !is.na(value))
c29data = c29data[c("year","indicator","value")]
c29.oda.max <- max(subset(c29data,indicator==indicators[2])$value,na.rm=TRUE)
c29.perc.max <- max(subset(c29data,indicator==indicators[1])$value,na.rm=TRUE)
c29.ratio = (c29.oda.max/c29.perc.max)*1.25
c29.oda.max = c29.oda.max*1.25
for(j in 1:length(indicators)){
  ind = indicators[j]
  indname = c29names[j]
  c29data$indicator[which(c29data$indicator==ind)] = indname
}

# Then we set up dummy key data to make pretty legends
c29.key.data.2 = data.frame(year=as.numeric(rep(NA,1)),indicator=c29names[2],value=as.numeric(rep(NA,1)))
c29.key.data.1 = data.frame(year=as.numeric(rep(NA,1)),indicator=c29names[1],value=as.numeric(rep(NA,1)))

# Then I predefine some styles and colours
simple_style = theme_bw() +
  theme(
    panel.border = element_blank()
    ,panel.grid.major = element_blank()
    ,panel.background = element_blank()
    ,plot.background = element_blank()
    ,panel.grid.minor = element_blank()
    ,axis.line = element_line(colour = "black")
    ,text = element_text(family="Averta Regular")
  )
yellow <- "#FCC97A"
orange <- "#F39000"
blue <- "#475C6D"
dark.grey <- "#A0ADBB"
yellowFill <- scale_fill_manual(values=c(yellow))
orangeColor <- scale_color_manual(values=c(orange))

ggplot(subset(c29data,indicator==c29names[2]),aes(x=year,y=value)) +
  geom_area(alpha=1,show.legend=F,color=blue,fill=yellow) +
  geom_point(data=c29.key.data.2,aes(group=indicator,fill=indicator),size=12,color=blue,stroke=1.5,shape=21) +
  geom_line(data=subset(c29data,indicator==c29names[1]),aes(y=value*c29.ratio,color=indicator),size=2) +
  yellowFill +
  orangeColor +
  guides(fill=guide_legend(title=element_blank(),byrow=TRUE),color=guide_legend(title=element_blank(),byrow=TRUE)) +
  simple_style  +
  scale_y_continuous(
    expand = c(0,0),
    limits=c(0,max(c29.oda.max*1.1,1)),
    sec.axis = sec_axis(~./c29.ratio, name="% of total ODA")
  ) +
  theme(
    legend.position="top"
    ,legend.box = "vertical"
    ,legend.text = element_text(size=25,color=blue,family="Averta Regular")
    ,legend.justification=c(0,0)
    ,legend.box.just = "left"
    ,legend.direction="vertical"
    ,axis.title.x=element_blank()
    ,axis.title.y=element_text(size=20,color=blue,family="Averta Regular")
    ,axis.ticks=element_blank()
    ,axis.line.y = element_blank()
    ,axis.line.x = element_line(color=blue, size = 1.1)
    ,axis.text.y = element_text(size=25,color=dark.grey,family="Averta Regular")
    ,axis.text.x = element_text(size=25,color=blue,margin=margin(t=20,r=0,b=0,l=0),family="Averta Regular")
    ,panel.grid.major.y = element_line(color=dark.grey)
    ,legend.background = element_rect(fill = "transparent", colour = "transparent")
    ,legend.key.width = unit(1,"cm")
  ) + labs(y = y.lab)

# See https://github.com/devinit/gnr-country-profile-2018/blob/master/charts.R for more examples

# Also importantly, you can save these charts as print quality vector files
# By default `ggsave` will save the last chart you displayed, or you could store your chart as a variable and save it that way
ggsave("output/zim_c29.png")
ggsave("output/zim_c29.svg")

# Ultimately, the options with ggplot are endless, so instead of exhaustively showing you options, I would
# Google around to see what's possible.
