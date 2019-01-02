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
save(crs,file="output/crs.RData")