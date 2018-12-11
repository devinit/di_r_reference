# Welcome to R! This line is a comment. Comments can begin with any number of hashes.
#### If a comment ends with four or more hashes, it can be collapsed in RStudio ####
# Collapsing a section hides code inbetween sections
#### End section ####

# In RStudio, you can run individual lines by placing your cursor at the end of a line and typing CTRL+Enter

# You can read help documents for any function by adding a ? to the beginning
?View

# R comes with a sample dataset called mtcars. To view it, run the function `View` with the argument `mtcars`
View(mtcars)

# You can print data in the console
print(mtcars)

# Print summary stats
summary(mtcars)

# Dimensions of dataframe
dim(mtcars)
nrow(mtcars)
ncol(mtcars)

# Column names and row names
colnames(mtcars)
names(mtcars)
rownames(mtcars)

# Make a copy of mtcars
mtcars2 = mtcars

# Drop the column `mpg` (set it to NULL)
mtcars2$mpg = NULL
names(mtcars2)

# You can make arbitrarily named variables with the equal sign `=` or assignment arrow `<-`
variable.one = 1
variable.two = 2

# Check equality
variable.one == variable.two
variable.one != variable.two
variable.one < variable.two
variable.one <= variable.two

# The data can be `character` meaning it's text. `integer` or `double` meaning numbers, or a `factor` a number representing text.
is.numeric(variable.one)
is.character("hello world")
test.factor = "hello world"
test.factor = factor(test.factor)
is.factor(test.factor)
typeof(test.factor)

# These variables are all stored as single-length vectors in R. A vector is just a single-dimension list of data.
# You can use the `c` function, short for concatenate, to combine single vectors into longer vectors
commands = c("stop","drop","roll")
steps = c(1, 2, 3)

# Several vectors can be combined into a `dataframe`, a data structure with rows and columns
on.fire = data.frame(steps,commands)
View(on.fire)

# on.fire is a dataframe with 3 observations and 2 variables
# Variables can be accessed with an $ sign
on.fire$steps

# Row and columns can be accessed using square brackets `[]`
# Row number comes first, followed by a comma, followed by column name/number
on.fire[1,1]
on.fire[1,"steps"]
on.fire[1,2]
on.fire[1,"commands"]
on.fire[2,"commands"]

# You can check if a variable is contained within a vector via the `%in%` operator
"stop" %in% on.fire$commands

# Which column of mtcars2 has the name "hp"?
which(names(mtcars2)=="hp")

# Use this knowledge to change the third name to "hp2"
names(mtcars2)[3] = "hp2"

# Or instead of typing in "3" directly, we can substitute the above formula into the index
names(mtcars2)[which(names(mtcars2)=="hp2")] = "hp3"

# Notice here we're not using a comma to index. This is because `names(mtcars2)` has just one dimension
names(mtcars2)[3]

# You can send messages to the console for debugging
message("Hello")

# You can have R loop through a vector, performing an action on every item in the vector
for(command in on.fire$commands){
  message(command)
}

# You could also access the same data by indexing the data frame
for(i in 1:nrow(on.fire)){
  the.message = on.fire[i,"commands"]
  message(the.message)
}

# In the above example, we can create a vector from 1 to 3 (the number of rows of on.fire) using the : operator
1:3
1:nrow(on.fire)

# You can write a dataframe to a csv using `write.csv`
write.csv(on.fire, "on_fire.csv")

# Wait, where did we just save that? `getwd` checks the current working directory
getwd()

# If you want to change where R reads and writes files, use `setwd`
setwd("~")
write.csv(on.fire, "on_fire.csv")

# You can also read csvs with `read.csv`
on.fire2 = read.csv("on_fire.csv")
View(on.fire2)

# Notice how it gained an extra column called `X`? This is the row name, and by default R saves it with csvs
# To turn it off, tell read.csv `row.names=FALSE`
write.csv(on.fire, "on_fire.csv", row.names=FALSE)
on.fire2 = read.csv("on_fire.csv")
View(on.fire2)

# Since R is free and open source, there are many different extensions written for it.
# You can install new extensions with `install.packages`
install.packages("ggplot2")

# And you can load new packages with `library` or `require`
library(ggplot2)
