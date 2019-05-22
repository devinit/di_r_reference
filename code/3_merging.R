list.of.packages <- c("data.table","WDI")
new.packages <- list.of.packages[!(list.of.packages %in% installed.packages()[,"Package"])]
if(length(new.packages)) install.packages(new.packages)
lapply(list.of.packages, require, character.only=T)

# Tired of VLOOKUPs and linked Excel spreadsheets?
# Merging files in R allows you to keep references to data in memory, and merge them once
# Instead of having Excel constantly check for linked files.

# This will be a short module, but merging is often one of the most performed
# operations at DI, so it's critically important!

# Let's start with some sample datasets from the World Bank WDI.
# We've already imported the package, so let's list out some indicators.
# Let's try and find total population, and GDP in constant USD
pop_results = WDIsearch("population, total")

# Notice the search results say one result, with the indicator code "SP.POP.TOTL", this is what we'll use
# to make a query of the World Bank API
pop = WDI("SP.POP.TOTL",country="all",start=1960,end=2018)
View(pop)

# And now GDP in constant USD
gdp_results = WDIsearch("gdp")
# This one is a bit further down
gdp_results[52,]
gdp = WDI("NY.GDP.MKTP.KD",country="all",start=1960,end=2018)

# Critically important in merging datasets is understanding that the text must match verbatim
# We can check to see how well two columns match using set theory
# First, the `unique` function reduces a column into only the unique observations
non_unique_set = c("a","a","a","b","b","b")
unique(non_unique_set)
# and second, the `setdiff` function shows us any differences between two sets.
set1 = c("a","b","c")
set2 = c("a","b","d")
setdiff(set1,set2)
setdiff(set2,set1)

# Note, that setdiff shows you observations of the first argument that are different from the second
# So therefore `setdiff(set1,set2)` is not equal to `setdiff(set2,set1)`
# When checking country name variance, you might want to check both directions

setdiff(unique(pop$iso2c), unique(gdp$iso2c))
# This should return `character(0)`, meaning a character vector of length 0, this means there are no differences.
setdiff(unique(gdp$iso2c), unique(pop$iso2c))
# Likewise this direction. In otherwords the two sets are identical.

# Now, before we merge the datasets, always check to see how many observations you currently have for each
nrow(pop)
nrow(gdp)

# By default, the merge function will drop observations that it cannot find a match for. To prevent this default,
# you must set either `all=TRUE` or one of `all.x=TRUE` or `all.y=TRUE`
# `all=TRUE` means you keep all observations of both datasets, regardless of match.
# The first dataset you put into the merge function is treated as `x` so `all.x=TRUE` means keep all observations
# from the first dataset, but only keep the matching observations from `y`. And `all.y` is vice versa.

# To start, because these data came from the same source, we can expect that they will have the exact same countries and years
# But gaps in this data probably vary between population and gdp. Let's first drop rows that are missing data.
pop = pop[complete.cases(pop),]
gdp = gdp[complete.cases(gdp),]
nrow(pop)
nrow(gdp) # Notice how the number of observations have changed

setdiff(unique(pop$iso2c), unique(gdp$iso2c)) # And in fact, now we have some ISO codes that are in pop, but not in GDP.
# So let's try the default merge
default_merged_pop = merge(pop,gdp,by=c("iso2c","country","year"))

# And check to see the length of the result
nrow(default_merged_pop)
nrow(default_merged_pop) == nrow(pop)
nrow(pop) - nrow(default_merged_pop) # It's about 3,894 rows shorter!

# This would be fine in the context of calculating GDP per capita. Because we cannot calculate it without valid
# observations of both variables, so dropping missing rows is of no consequence.
default_merged_pop$gdp_per_cap = default_merged_pop$NY.GDP.MKTP.KD/default_merged_pop$SP.POP.TOTL

# Just a little chart for fun
uk_default = subset(default_merged_pop,iso2c=="GB")
plot(uk_default$gdp_per_cap~uk_default$year,type="l")

# Here's what the code looks like if you want to keep all obs of X
x_merged = merge(pop,gdp,by=c("iso2c","country","year"),all.x=TRUE)
# And likewise for all observations
all_merged = merge(pop,gdp,by=c("iso2c","country","year"),all=TRUE)


# Now, remember how I said to always look at the original number of observations?
# This is not only important for missing data, it's important for duplicated data as well.
# The `merge` function assumes that your `y` dataset has unique observations of the columns
# you specify in the `by` argument. Let's try doubling up gdp and see what happens
gdp_double = rbind(gdp,gdp)
test_merge = merge(pop,gdp_double,by=c("iso2c","country","year"))
nrow(test_merge)
# Wow! 22506 rows, despite the fact that we only have 15147 observations of pop.
# This is because it will match duplicates of y to every observation of x, and make a new observation of x
# for every duplicate observation of y.

# So the moral of the story is to first check whether the names you're merging on match
# And second to always check the observations before and after the merge