list.of.packages <- c("data.table","XML","ggplot2","scales","varhandle")
new.packages <- list.of.packages[!(list.of.packages %in% installed.packages()[,"Package"])]
if(length(new.packages)) install.packages(new.packages)
lapply(list.of.packages, require, character.only=T)

# Check your WD before trying to load files
setwd("~/git/di_r_reference")

# Load a reference to the file
dfid_ug = xmlParse("data/dfid-ug.xml")

# XML is hierarchical. So we need to start at the top of the hierarchy, or the "root"
rootnode = xmlRoot(dfid_ug)
xmlSize(rootnode) # Number of nodes descendant from the root

# We extract a list of the child nodes. At this level, the children are the activities
activities = xmlChildren(rootnode)
names(activities)

# Let's work with just the first activity for now. We will loop through them later
activity = activities[[1]]

# To see attributes directly attached to the activity, we use the xmlAttrs function
act_attribs = xmlAttrs(activity)
names(act_attribs) # See all the names of the attributes, and store the ones we want
update = act_attribs[["last-updated-datetime"]]
default_currency = act_attribs[["default-currency"]]

# Again, hierarchy, so we need to access the children of the activity
activity_children = xmlChildren(activity)
names(activity_children) # Here, the names are the different sub-elements of the activity

# Knowing that these elements are in there, we can use the xPath to pull them straight out of the activity element
id_elem = getNodeSet(activity,"iati-identifier")
# Since it returns a list, we can use sapply to extract the data, no matter the length
iati_identifier = sapply(id_elem,xmlValue)

# Pull out some other useful info. If it's stored in an attribute rather than a value, we use "xmlGetAttr"
recip_elem = getNodeSet(activity,"recipient-country")
recipients = sapply(recip_elem,xmlGetAttr,"code")

# For activity 1, there are no transactions. Let's pull out all of the transactions from all of the activities
trans_elems = getNodeSet(rootnode,"iati-activity/transaction")

# Set up an empty list for storing data
trans_list = list()
trans_list_index = 1

# Let's make a function that looks for an attribute, but returns a default if none is found
xmlGetAttrDefault = function(node,attribute_name,default_value){
  attribute_value = xmlGetAttr(node,attribute_name)
  if(is.null(attribute_value)){
    return(default_value)
  }
  return(attribute_value)
}

# loop through the trans_elems to extract data
for(trans_elem in trans_elems){
  type_elems = getNodeSet(trans_elem,"transaction-type")
  trans_type = sapply(type_elems,xmlGetAttr,"code")
  value_elems = getNodeSet(trans_elem,"value")
  values = sapply(value_elems,xmlValue)
  currencies = sapply(value_elems,xmlGetAttrDefault,"currency",default_currency)
  dates = sapply(value_elems,xmlGetAttrDefault,"value-date","")
  trans.df = data.frame(value=values,currency=currencies,date=dates,type=trans_type)
  trans_list[[trans_list_index]] = trans.df
  trans_list_index = trans_list_index + 1
}

# Added fill=T here just in case an element is missing from a data.frame
# Fill will create a new column and fill it with NA where it didn't exist before
# So in case one transaction is missing a type, we can still rbind
all_transactions = rbindlist(trans_list,fill=T)
View(all_transactions)

# See all unique transaction types
unique(all_transactions$type)

# Set up a small key to decode via http://reference.iatistandard.org/201/codelists/TransactionType/
type_key = c(
  "Incoming Funds",
  "Commitments",
  "Disbursements",
  "Expenditure",
  "Interest Repayment",
  "Loan Repayment",
  "Reimbursement",
  "Purchase of Equity",
  "Sale of Equity",
  "Credit Guarantee"
  )

# Notice how the code level matches the key index, so we can translate a code via indexing
type_key[1]

# We need to unfactor type. `as.numeric` just captures the underlying integer instead of the intended value
all_transactions$type = unfactor(all_transactions$type)
all_transactions$type_name = type_key[all_transactions$type]

# Turn the value into a numeric column
all_transactions$value = as.numeric(all_transactions$value)
# Extract the year from the date
all_transactions$year = as.numeric(substr(all_transactions$date,1,4))

# Calculate the sum by year
all_trans_tab = data.table(all_transactions)[,.(value=sum(value,na.rm=T)),by=.(year,type_name)]
ggplot(all_trans_tab,aes(x=year,y=value,color=type_name,group=type_name)) +
  geom_line() +
  scale_y_continuous(labels=dollar_format(prefix="£")) +
  theme_classic() +
  labs(x="Transaction year",y="Total transaction value",title="DFID transactions to Uganda, 2000-2018") +
  guides(color=guide_legend(title="Transaction type"))
