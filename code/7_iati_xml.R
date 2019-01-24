list.of.packages <- c("data.table","XML","ggplot2","scales")
new.packages <- list.of.packages[!(list.of.packages %in% installed.packages()[,"Package"])]
if(length(new.packages)) install.packages(new.packages)
lapply(list.of.packages, require, character.only=T)

# Check you WD before trying to load files
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
  value_elems = getNodeSet(trans_elem,"value")
  values = sapply(value_elems,xmlValue)
  currencies = sapply(value_elems,xmlGetAttrDefault,"currency",default_currency)
  dates = sapply(value_elems,xmlGetAttrDefault,"value-date","")
  trans.df = data.frame(value=values,currency=currencies,date=dates)
  trans_list[[trans_list_index]] = trans.df
  trans_list_index = trans_list_index + 1
}

all_transactions = rbindlist(trans_list)
View(all_transactions)

# Turn the value into a numeric column
all_transactions$value = as.numeric(all_transactions$value)
# Extract the year from the date
all_transactions$year = as.numeric(substr(all_transactions$date,1,4))

# Calculate the sum by year
all_trans_tab = data.table(all_transactions)[,.(value=sum(value,na.rm=T)),by=.(year)]
ggplot(all_trans_tab,aes(x=year,y=value)) +
  geom_line(color="blue") +
  scale_y_continuous(labels=dollar_format(prefix="£")) +
  theme_classic() +
  labs(x="Transaction year",y="Total transaction value",title="DFID transactions to Uganda, 2000-2018")
