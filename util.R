
getvalue <- function(l, k) {
	value = l$"_source"$values[k][[1]]$instances[[1]]$value
}

gettimestamp <- function(l) {
	t = l$"_source"$timestamp$s
	t
}

getname <- function(l) {
	  name = l$name
}
	
getinstance <- function(l) {
	name = l$instance
}

getval <- function(l, k) {
	instances = sapply(l$"_source"$values[k][[1]]$instances, getinstance)
  	count = length(instances)
  	if (count == 1) {
		v = getvalue(l, k)
 	} else {
   		v = getvalues(l, k)
	}	
 	v
}


getinstanceCount <- function(l, k) {
	instances = sapply(l$"_source"$values[k][[1]]$instances, getinstance)
  	count = length(instances)
	count
}

getvalue <- function(l, k) {
	#print(l)
	value = l$"_source"$values[k][[1]]$instances[[1]]$value
}

getvalues <- function(l, k) {
	instances = list()
	instances = sapply(l$"_source"$values[k][[1]]$instances, getinstance)
	l1 = list()
	for (count in 1:length(instances)) {
		#l1[l$"_source"$values[k][[1]]$instances[[count]]$instance] = l$"_source"$values[k][[1]]$instances[[count]]$value
		l1[count] = l$"_source"$values[k][[1]]$instances[[count]]$value
	  }
	l1
}
diffList <- function(l) {
	ldiff = list()
	l = unlist(l)
	for (i in 2:length(l)) {ldiff[i-1] = l[[i]] - l[[i-1]] }
	ldiff = lapply(ldiff, function(x) x/30 )
	ldiff
}

kbsToGb <- function(bytes) {
	mbs = bytes / (1024 * 1024)
	mbs = round(mbs, 2)
	mbs
}

kbsToMb <- function(kbs) {
	mbs = kbs / 1024
	mbs = round(mbs, 2)
	mbs
}

bytesToMb <- function(bytes) {
	mbs = bytes / (1024 * 1024)
	mbs = round(mbs, 2)
	mbs
}
