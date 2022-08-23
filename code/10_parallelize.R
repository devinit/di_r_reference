list.of.packages <- c(
  "data.table",
  # The packages required for parallelization
  "foreach", "doSNOW","snow", "doParallel" 
)
new.packages <- list.of.packages[!(list.of.packages %in% installed.packages()[,"Package"])]
if(length(new.packages)) install.packages(new.packages)
lapply(list.of.packages, require, character.only=T)

# Detect the number of cores to use and set up cluster
nCores <- detectCores() - 2
parallelCluster <- makeCluster(nCores,type = "SOCK",methods = FALSE) # Make a parallel cluster
setDefaultCluster(parallelCluster)
registerDoSNOW(parallelCluster)

# Tie R exit to the shutdown of cluster nodes
on.exit({
  try({
    cat("Attempting to stop cluster\n")
    stopImplicitCluster()        # package: `doParallel`
    stopCluster(parallelCluster) # package: `parallel`
  })
})

# Set up dummy data
sample_data = data.frame(n=c(1:1000000), category="whatever")
n_chunks = 500

# Split dummy data into chunks for parsing
chunk_steps = seq(0,nrow(sample_data), length.out = n_chunks + 1) + 1
data_chunks = list()
for(i in 1:n_chunks){
  data_chunks[[i]] = sample_data[c(chunk_steps[i]:(chunk_steps[i+1] - 1)),]
}

# Set up progress bar options
pb <- txtProgressBar(max = n_chunks, style = 3)
progress <- function(n) setTxtProgressBar(pb, n)
opts <- list(progress = progress)

# Perform operations on dummy data, iterating through 1:n_chunks into "chunk_n" inside the function, and cbinding results
sample_results = foreach(chunk_n=1:n_chunks, .combine = cbind, .options.snow = opts) %dopar% {
  this_chunk = data_chunks[[chunk_n]]
  this_chunk$n = this_chunk$n * 2
  return(this_chunk)
}

# Stop cluster
stopCluster(parallelCluster)

# Compare results
message(paste(sample_data$n[1:10], collapse=", "))
message(paste(sample_results$n[1:10], collapse=", "))