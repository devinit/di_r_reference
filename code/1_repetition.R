# In this module we'll discuss various methods of repetition.
# From here on out, rather than adding in `library` or `require` for each package,
# I'm going to use this stock piece of code that will check and install required libraries.
list.of.packages <- c("data.table","ggplot2")
new.packages <- list.of.packages[!(list.of.packages %in% installed.packages()[,"Package"])]
if(length(new.packages)) install.packages(new.packages)
lapply(list.of.packages, require, character.only=T)

# For testing purposes, the country data from the GNR 2018 country profiles has been placed in the data folder.
# You may need to change your wd depending on where this file lives on your computer.
wd = "~/git/di_r_reference"
setwd(wd)
dat = read.csv("data/gnr_2018_data.csv",na.strings="",as.is=T)

# Check the column names
names(dat)

# This is called a for loop. You can incrementally assign a value to a variable from a vector, and operate on it within the loop
vector = c(1,2,3)
for(element in vector){
  message(element)
}

# Alternatively, you can use the length of the vector to index it, and loop through the index
for(i in 1:length(vector)){
  message(vector[i])
}

# Looping through column names
for(nam in names(dat)){
  message(nam)
}

# Here is a function. You can use it to operate on a series of inputs called `arguments`
xyz = function(x,y,z){
  if(x > y){
    return(z)
  }else{
    return(1-z)
  }
}
xyz(1,2,0.25)
xyz(2,1,0.25)

# Once defined, you can use a function any number of times. It's great for keeping your code tidy, especially in loops
# Here's a function I used in the GNR profiles to tell whether a vector is able to be converted to a number
numericable = function(vec){
  vec = vec[complete.cases(vec)]
  num.vec = as.numeric(vec)
  num.vec = num.vec[complete.cases(num.vec)]
  if(length(num.vec)==length(vec)){
    return(T)
  }
  return(F)
}

numericable(c(1,2,3))
numericable(c("1","2","3"))
numericable(c("Hello","Goodbye")) # This will give you a warning message.
# Extract all indicators from profile data
inds = unique(dat$indicator)
# Loop through inds, check whether data is numericable, if so, print the mean
for(ind in inds){
  ind.data = subset(dat,indicator==ind)
  if(numericable(ind.data$value)){
    message(ind,mean(as.numeric(ind.data$value),na.rm=T))
  }
}

# My prefered way to operate on subgroups of data is with the data.table package
dat.tab = data.table(dat)
dat.means = dat.tab[,.(value=mean(as.numeric(value))),by=.(year,indicator)]

# We'll touch more on ggplot2 in later modules, but I quickly want to show how you can create charts in a loop
dat.means = dat.means[complete.cases(dat.means),]
for(ind in unique(dat.means$indicator)){
  sub.dat = subset(dat.means,indicator==ind)
  if(nrow(sub.dat)>1){
    p = ggplot(sub.dat,aes(x=year,y=value)) + geom_line() + theme_classic()
    ggsave(paste0("output/",ind,".png"),p)
  }
}
