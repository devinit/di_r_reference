list.of.packages <- c("data.table","scrapeR","tabulizer","miniUI","jsonlite")
new.packages <- list.of.packages[!(list.of.packages %in% installed.packages()[,"Package"])]
if(length(new.packages)) install.packages(new.packages)
lapply(list.of.packages, require, character.only=T)
# Watch the output of this lapply. If you see any that return `FALSE` that means
# At least one package failed to install. It will most likely be tabulizer, which requires
# you install and set JAVA_HOME. See https://docs.oracle.com/cd/E19182-01/820-7851/inst_cli_jdk_javahome_t/ 
# for further instructions.

# Edit this working directory before trying to load these files
setwd("~/git/di_r_reference")

# First, we're going to extract tables from a series of 30 PDF files

# If you look in the "data" folder in this repo, you can see the pdfs in the "ghana_pdfs" folder.
# Go ahead and open one up to follow along with.

# These are the columns we want to extract
tab_col_names = c("sprog","desc","recurrent","domestic","external","total")

# We use `list.files` to grab a list of all the pdf file names in the ghana_pdfs folder.
pdfs = list.files(path="data/ghana_pdfs",pattern="*.pdf",full.names=TRUE)

# We set up an empty list to capture data as we loop through the pdfs.
dat.list = list()

# Now Tabulizer will try and guess where the data you want to extract is.
# If your data is a bit messy, you will need to use the `locate_areas` function first
# To find the boundaries of the columns. Try using the command below to get the `right`
# value from the `sprog` and `description` columns
locate_areas(pdfs[1])

# This is the process I used to get the boundaries between columns in the `columns` argument below.

# Loop through the pdfs
for(i in 1:length(pdfs)){
  pdf = pdfs[i]
  
  # Extract the district name from the pdf filename
  bname = basename(pdf)
  district = substr(bname,1,nchar(bname)-15)
  
  # Print out the district name to track our progress
  message(district)
  
  # Extract the tables
  tabs = extract_tables(
    pdf
    ,columns=list(c(95.7,395.6,482,576.5,667,756.6))
    ,guess=F
  )
  
  # Turn the extract into a data frame
  tab_dfs = lapply(tabs,data.frame)
  tab_df = rbindlist(tab_dfs)
  
  # In this case, we're looking for those codes specifically, so we throw out the rest
  relevant_rows = subset(tab_df,X1 %in% c("D101","D102","D201","D202","D203"))
  
  # Set nice column names
  names(relevant_rows) = tab_col_names
  
  # Reshape and remove commas from numeric data
  rel_rows_long = melt(relevant_rows,id.vars=c("sprog","desc"))
  rel_rows_long$value = as.numeric(gsub(",","",rel_rows_long$value))
  
  # Attach the district name to the data (since it's all going to be lumped together later)
  rel_rows_long$district = district
  # Add it to the list, repeat the loop until we get to the last pdf
  dat.list[[district]] = rel_rows_long
}

# Combine all of our extracted data frames
total_dat = rbindlist(dat.list)

# Write out to CSV
fwrite(total_dat,"output/total_educ_dat.csv")

# Check to see if any expected district names are not in the output
setdiff(substr(basename(pdfs),1,nchar(basename(pdfs))-15),unique(total_dat$district))
# Bonus points: can you figure out why the City of Kigali is missing from our output?

# Our next useful skill is web scraping, or gathering data from web pages.
# For example, take a look at this web document by PRESS https://tian-y.github.io/PRESS2017Maps/PRESS_2017_ZWE.htm
# Wouldn't it be nice if we could automatically extract all that data?

# Define the URL
url = "https://tian-y.github.io/PRESS2017Maps/PRESS_2017_ZWE.htm"

# Extract the ISO
iso3 = substr(url,51,53)

# Here's the magic bit. This navigates to the URL and returns to you the elements of the page
source = scrape(url, headers=T,follow=T,parse=T)[[1]]

# Using a syntax called "xPath" we extract all the script elements
# These are where the data is encoded
script_elems = getNodeSet(source,"//script")
script_vals = sapply(script_elems,xmlValue)
script_vals = trimws(script_vals[which(script_vals!="")])

# From inspecting the original site, I know the chart data is stored in the
# third, fourth, and fifth elements
chart_sources = sapply(script_vals[c(3,4,5)],fromJSON)
chart_1_data = chart_sources[[1]]$data
chart_2_data = chart_sources[[4]]$data
chart_3_data = chart_sources[[7]]$data

# We just need to manipulate the raw JSON data a little to get them into nice data frames
c1list = list()
for(rownum in 1:nrow(chart_1_data)){
  c1row = chart_1_data[rownum,]
  x = eval(c1row$x)[[1]]
  y = eval(c1row$y)[[1]]
  name = eval(c1row$name)[[1]]
  label = eval(c1row$text)[[1]]
  rowdf = data.frame(x,y,name,label)
  c1list[[rownum]] = rowdf
}
c1dat = rbindlist(c1list)

c2list = list()
for(rownum in 1:nrow(chart_2_data)){
  c2row = chart_2_data[rownum,]
  x = eval(c2row$x)[[1]]
  y = eval(c2row$y)[[1]]
  name = eval(c2row$name)[[1]]
  label = eval(c2row$text)[[1]]
  rowdf = data.frame(x,y,name,label)
  c2list[[rownum]] = rowdf
}
c2dat = rbindlist(c2list)

c3list = list()
for(rownum in 1:nrow(chart_3_data)){
  c3row = chart_3_data[rownum,]
  labels = eval(c3row$labels)[[1]]
  values = eval(c3row$values)[[1]]
  rowdf = data.frame(labels,values)
  c3list[[rownum]] = rowdf
}
c3dat = rbindlist(c3list)

c1dat$iso3 = iso3
c2dat$iso3 = iso3
c3dat$iso3 = iso3

# Nice little dataframes
View(c1dat)
View(c2dat)
View(c3dat)

# And now we extract the data from the table at the bottom.
# If you look at the xPath here, this is referencing the rows (tr), of the
# table body (tbody), of the table.
row_elems = getNodeSet(source,"//table/tbody/tr")
row_vals = sapply(row_elems,xmlValue)
# After accessing the row values, we split them into cells to turn it into a data frame
celllist = list()
for(j in 1:length(row_vals)){
  row_val = row_vals[j]
  cells = strsplit(row_val,"\n")[[1]]
  celldf = data.frame(t(cells))
  names(celldf) = c("Donor","Program Name","Date","Amount")
  celllist[[j]] = celldf
}
t1 = rbindlist(celllist)
t1$iso3 = iso3
View(t1)
