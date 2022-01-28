list.of.packages <- c("data.table","dotenv", "httr", "dplyr")
new.packages <- list.of.packages[!(list.of.packages %in% installed.packages()[,"Package"])]
if(length(new.packages)) install.packages(new.packages)
lapply(list.of.packages, require, character.only=T)
rm(list.of.packages,new.packages)

# Disclaimer: Whenever I write a guide for an API, URLs are liable to change

# Setup:
# 1. Prior to running this script, sign up for an account here https://developer.iatistandard.org/
# 2. Once you have an account, sign up for an API key
# 3. We're going to be using a .env file. This environment file will enable you to save
# credentials in the same folder as your R scripts, and as long as you remember to add
# it to your .gitignore file, you won't accidentally upload your key. So after receiving your
# API key, make a file in this folder named `.env` and write this text inside of it:
# API_KEY=XXX-YOUR-API-KEY-HERE-XXX

# Then, the `dotenv` R package will be able to pick up that key and bring it into R without
# writing it in the R script directly.
load_dot_env()
api_key = Sys.getenv("API_KEY")

# Next, we can send a simple request to the Datastore activity endpoint to see
# what columns are available. I'm just splitting this line by paste0 to make it
# more easily readable.

# To explain this URL, we're querying the `select` SOLR function of the `activity`
# collection. There is also a `transaction` collection, and may be more in the future.
# `q` is the main query parameter. For now we're just requesting everything with *:*
# `fl` allows you to select columns, we're requesting them all with *
# `wt` allows you to set the output format, e.g. `json` or `csv` or `xml`
# `rows` allows you to select a number of rows. 0 for now to just get the header.

test_url = paste0(
  "https://api.iatistandard.org/datastore/activity/select?",
  "q=*:*",
  "&fl=*",
  "&wt=csv",
  "&rows=0"
)

# Use the `GET` request from `httr` to pass a query to the API, and add our key
# as a header
req = GET(
  URLencode(test_url),
  add_headers(`Ocp-Apim-Subscription-Key` = api_key)
)
res = content(req)

# Split out headers by commas. Over 300!! Ignore the \n at the end of the last one.
available_columns = strsplit(res, split=",")[[1]]


# `rows` has a limitation of 1000, so we'll need to paginate to get everything we want
# Below is an example of a query I wrote for the IATI results framework. It queries
# data at 1000 rows at a time in a `while` loop, and then increments the `start` figure by 1000
# on every loop. While paginating, make sure you're also using `sort` so the data stays in
# the same order.

# Setup empty list and index to collect results
results_list = list()
results_index = 1

# Setup dummy `docs` to get our `while` loop started. The loop will automatically stop when
# it reaches the end because it finds the last page by looking for a result with less than 1000
docs = rep(0, 1000)

# And note how I'm using the `q` parameter here to select only UK gov activities with transactions
# in the type 3 or 4. You'll need to use the IATI codelists if you want to find out
# what those codes mean https://iatistandard.org/en/iati-standard/203/codelists/transactiontype/

start_num = 0
api_url_base = paste0(
  "https://api.iatistandard.org/datastore/activity/select?",
  "q=reporting_org_ref:(GB-GOV-)",
  " AND (transaction_value:[* TO *]) AND (transaction_transaction_type_code:(3 OR 4))&",
  "fl=iati_identifier default_currency reporting_org_ref ",
  "transaction_transaction_type_code transaction_transaction_date_iso_date ",
  "transaction_value transaction_value_value_date transaction_value_currency&",
  "sort=iati_identifier asc&",
  "rows=1000&start="
)
while(length(docs)==1000){
  message(start_num)
  req = GET(
    URLencode(paste0(api_url_base, format(start_num, scientific=F))),
    add_headers(`Ocp-Apim-Subscription-Key` = api_key)
  )
  res = content(req)
  docs = res$response$docs
  # Since we know there will only be 1 identifier, default_currency, and reporting_org
  # per activity, and X of the transaction-level variables, we can simply flatten the json
  # result with rbindlist, which will replicate the activity-level vars across the transactions
  docs.df = rbindlist(docs, fill=T)
  docs.df = docs.df %>% mutate_all(function(x){
    x[which(sapply(x, length)==0)] = NA
    return(unlist(x))
  })
  # This does, however, leave some `list` data types in cells due to some NULL values
  # So the mutate_all above just iterates through the rows and removes the NULLs and unlists
  docs.df = subset(docs.df, transaction_transaction_type_code %in% c(3, 4))
  # Even though I requested type 3 and 4 above, the API will give me all transactions
  # from all activities that have transactions of type 3 and 4. So to slim down the data
  # collected, I throw away the other transactions here before appending them
  results_list[[results_index]] = docs.df
  results_index = results_index + 1
  start_num = start_num + 1000
  # End of the loop, iterate start, start again
}

# In the end, you're left with a basic dataset of IATI data
results = rbindlist(results_list, fill=T)

