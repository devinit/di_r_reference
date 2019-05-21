list.of.packages <- c("data.table","reshape2","httr","readr")
new.packages <- list.of.packages[!(list.of.packages %in% installed.packages()[,"Package"])]
if(length(new.packages)) install.packages(new.packages)
lapply(list.of.packages, require, character.only=T)

#### OLD API INSTRUCTIONS ####

# The DDH API is located here: http://212.111.41.68:8000/

# Available endpoints are
# `/all_tables` - lists all tables
# `/meta_data` - lists some DI concepts, may be more useful in the future
# `/single_table` - Allows access to a single DDH table
# `/multi_table` - Allows access to multiple DDH tables at once

# Let's start by seeing what's available
all_tables = fread("http://212.111.41.68:8000/all_tables?format=csv")
View(all_tables)

# The DDH uses "schemas" to organise data. Let's see the available ones
unique(all_tables$table_schema)
# And look at the Spotlight on Uganda specifically
sou_2017 = subset(all_tables,table_schema=="spotlight_on_uganda_2017")
View(sou_2017)

# Using a table name from `all_tables`, we can query the API for that data

ug_pop = fread("http://212.111.41.68:8000/single_table?indicator=uganda_total_pop&format=csv")
View(ug_pop)
kampala = subset(ug_pop,name=="Kampala")
plot(value~year,data=kampala,type="l")

# The following parameters are also available to customize single or multitable endpoint queries
# indicator: ?indicator=population_total
# entities: ?entities=UG,KE,NA
# start_year: ?start_year=2000
# end_year: ?end_year=2001
# limit: ?limit=100
# offset: ?offset=200
# format: ?format=xml (available options are xml, json, or csv)

# So you can just get total population for Uganda and Kenya from the year 2000 like so:
ug_ke_pop = fread("http://212.111.41.68:8000/single_table?indicator=population_total&entities=UG,KE&start_year=2000&end_year=2000&format=csv")
View(ug_ke_pop)

# For now, you don't need to bother with limit and offset unless you think the data has more than a million rows.
# Limit sets the limit on returned data rows, and offset allows you to paginate through it.

# `/multi_table` also behaves exactly like `/single_table` but will return you two or more indicators in long form
# For e.g.

pop_gov_rev = fread("http://212.111.41.68:8000/multi_table?indicators=govt_revenue_pc_gdp,population_total&format=csv")

# Which we can reshape if you so desire
pop_gov_rev = subset(pop_gov_rev,budget_type=="actual" | indicator=="population_total")
pop_gov_rev$budget_type = NULL
pop_gov_rev.m = melt(pop_gov_rev,id.vars=c("di_id","name","year","indicator"))
pop_gov_rev.w = dcast(pop_gov_rev.m, di_id+name~indicator+year+variable)
View(pop_gov_rev.w)

#### NEW DDW UI INSTRUCTIONS ####

# Change these to match your username and password from the DDW Analyst UI. Do not commit them to Github!
ddw_user = "user"
ddw_pass = "pass"

# The DDW Analyst UI is build on a REST API that uses secure authorization tokens
# First we need to POST the username and password to the service to generate a token
base_url = "http://ddw.devinit.org/"
token_response = POST(
  paste0(base_url,"api/auth/login/"),
  authenticate(ddw_user, ddw_pass)
)
if(token_response$status_code==200){
  token = content(token_response)$token # Collect the token from the response for future queries
}else{
  message("Something went wrong with logging in!")
}

# Now that we've logged in, we can use the login response to see a list of queries associated with our account

queries = content(token_response)$user$operation_set

# Check if you've made any queries, otherwise default to a public one
if(length(queries)>0){
  first_query_id = queries[[1]]$id
}else{
  first_query_id = 262
}

# And once we've got a specific query, we can export the data

query_data_response = POST(
  paste0(base_url, "api/export/", first_query_id, "/"),
  body=list("token"=token),
  encode="form"
)

if(query_data_response$status_code==200){
  query_data = content(query_data_response)
}else{
  message("Something went wrong with loading the data!")
}
