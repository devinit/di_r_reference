list.of.packages <- c("data.table")
new.packages <- list.of.packages[!(list.of.packages %in% installed.packages()[,"Package"])]
if(length(new.packages)) install.packages(new.packages)
lapply(list.of.packages, require, character.only=T)

if(.Platform$OS.type == "unix"){
  wd = "~/git/di_r_reference"
}else{
  wd = "C:/git/di_r_reference"
}
setwd(wd)

# We hardly work with what most experts would consider big data
# Three Vs (volume, velocity, and variety)
# But R can be useful for data too big to fit into Excel (> 1 million rows)

# First we need to download a lot of data! This zip is the raw CRS as downloaded from the OECD.
# Download this link as crs.zip and save it in the output folder of this repo
# https://drive.google.com/file/d/1LwyElpopERmOex13r0qEDy8FX1y56Fn5/view?usp=sharing
if(file.exists("output/crs.zip")){
  if(!dir.exists("output/crs")){
    unzip("output/crs.zip",exdir="output/crs")
  }
}else{
  message("Download the zip file first!")
}

# List out the text files
txts = list.files("output/crs/","*.txt",full.names=T)

# Initialize an empty list
data.list = list()
data.index = 1

# Loop through, and use the `fread` function from `data.table` package.
# CRS has some embedded null characters, which we need to fix.
for(txt in txts){
  message(basename(txt))
  r = readBin(txt, raw(), file.info(txt)$size)
  r[r==as.raw(0)] = as.raw(0x20) ## replace with 0x20 = <space>
  writeBin(r, txt)
  tmp = fread(txt,sep="|")
  data.list[[data.index]] = tmp
  data.index = data.index + 1
}

crs = do.call(rbind,data.list)
message("Total rows: ",nrow(crs))
# Save it all as a compressed RData file
save(crs,file="output/crs.RData")

# Once it's saved, we can programmatically clear the environment
rm(list=ls())

# This command clears your memory, to ensure we're not holding onto any unnecessary data
# It stands for "Garbage collection"
gc()

# To load the file we saved 
load("output/crs.RData")

# I highly recommend you don't `View` this file. It will get really slow
# Rather, use `names` and other tools to inspect it
names(crs)
summary(crs$Year)
year.freq = data.frame(table(crs$Year))

# Any CRS project that has the word "health" in the long description
health = crs[grepl("health",crs$LongDescription,ignore.case=T),]
nrow(health)

# Warning messages mention invalid strings, let's look at them (probably Spanish?)
crs$LongDescription[c(211216,211217,212766,212985,213066)]

# Can be avoided by reading string as Bytes
byte_health = crs[grepl("health",crs$LongDescription,ignore.case=T,useBytes=T),]
nrow(byte_health)

# Calculate the set difference, and see a sample
diff = setdiff(byte_health$LongDescription, health$LongDescription)
diff[1]

# As you can see, 4,435 rows excluded. So it's important to consider special characters
