

# multicore/MPI test

# benchmarks multicore against single thread.



library(snow)

reps <- 5	# how many repetitions

# define a function that is reasonably costly to compute

## R implementation of recursive Fibonacci sequence
fibR <- function(n) {
    if (n == 0) return(0)
    if (n == 1) return(1)
    return (fibR(n - 1) + fibR(n - 2))
}

# wrapper that serially computes fibR for a list of values
serfun <- function(joblist){
	
	# take time
	t1 <- proc.time()[3]
		
	# take name
	nname <- Sys.info()["nodename"]
	names(nname) <- NULL

	# do the work
	# 40 times over
	for (i in 1:40){
		nums <- lapply(joblist, function(x) fibR(x))
	}

	res <- list(node=nname,time=proc.time()[3]-t1,vals=nums)
	return(res)
}

# make cluster
mycl <- makeCluster(type='MPI')

num.worker <- length(clusterEvalQ(mycl,Sys.info()))	# num.worker chosen in submit script

# source functions on cluster
clusterEvalQ(mycl,source("slaves.r"))


# here are the jobs to do on each core.
# each core needs to compute the fibonacci sequence up to 30 ten times over
jobs <- lapply(1:num.worker,function(x) rep(30,10))	

res <- list()

# do reps replications of that test
for (i in 1:reps){
	res[[i]] <- parLapply(mycl,jobs,serfun)
}



# analyze
library(data.table)
d <- data.table(expand.grid(repl=1:reps,run=1:num.worker),key=c("repl","run"))
for (i in 1:reps) for (r in 1:num.worker) d[.(i,r),node := as.character(res[[i]][[r]]$node)]
for (i in 1:reps) for (r in 1:num.worker) d[.(i,r),time := as.numeric(res[[i]][[r]]$time)]


save(res,d,file="timer.RData")

# library(ggplot2)
# pdf("timing.pdf")
# ggplot(d,aes(run,time)) + geom_point(aes(color=node,shape=factor(repl))) + scale_y_continuous(name="seconds") + scale_x_continuous(name="function evaluation number")
# dev.off()
print("goodbye")
stopCluster(mycl)
