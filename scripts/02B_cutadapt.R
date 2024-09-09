# load file of functions and check installed packages
source("scripts/functions.R")

## get command line arguments (lengths of primers or sequence to be trimmed from the left of the forward/R1 and reverse/R2 reads)
option_list = list(
  make_option(c("-D", "--dir"), type="character", default=NULL,
              help="Directory of raw data files.", metavar="character"),
  make_option(c("-F", "--Flength"), type="character", default=NULL, 
              help="Number of bases to trim from the start of the forward read", metavar="character"),
  make_option(c("-R", "--Rlength"), type="character", default=NULL, 
              help="Number of bases to trim from the start of the reverse read", metavar="character"),
  make_option(c("-E", "--email"), type="character", default=NULL,
              help="Email address to receive job notifications.", metavar="character")
); 
 
opt_parser = OptionParser(option_list=option_list);
opt = parse_args(opt_parser);

## get cwd and the directory of data from the -D flag.
path<-getwd()
input_files <- paste(path,"/", opt$dir, sep="")

## figure out the universal section of the file names (I.e. something like 001_R1.fastq.gz)
file_exts <- guess_file_extension(input_files)

## redefine filtNs based on what is actually in the dirs (sometimes an input sample is completely removed by filterAndTrim previously)
fnFs.filtN <- sort(list.files(paste(path, "/working_data/filtN", sep=""), pattern = glob2rx(paste("*", file_exts$R1, sep="")), full.names = TRUE))
fnRs.filtN <- sort(list.files(paste(path, "/working_data/filtN", sep=""), pattern = glob2rx(paste("*", file_exts$R2, sep="")),  full.names = TRUE))

## write these out in case different from the filtN lists generated from the raw inputs
saveRDS(fnFs.filtN, file = paste(path, "/R_objects/02_fnFs.filtN.rds", sep=""))
saveRDS(fnRs.filtN, file = paste(path, "/R_objects/02_fnRs.filtN.rds", sep=""))

# create directory for to received trimmed data, we'll use "cutadapt" to retain compatibility with subsequent scripts 
path.cut <- file.path(paste(path, "/working_data/cutadapt", sep=""))
if(!dir.exists(path.cut)) dir.create(path.cut)

## redefine the cut dirs based on what is going in
fnFs.cut <- gsub("/filtN", "/cutadapt", fnFs.filtN)
fnRs.cut <- gsub("/filtN", "/cutadapt", fnRs.filtN)

## write the cut objects out
## write objects to pass to next script
saveRDS(fnFs.cut, file = paste(path, "/R_objects/02_fnFs.cut.rds", sep=""))
saveRDS(fnRs.cut, file = paste(path, "/R_objects/02_fnRs.cut.rds", sep=""))

## check the order of files going in/out
if (isFALSE(identical(sapply(strsplit(fnFs.cut,"cutadapt/"), `[`, 2), sapply(strsplit(fnFs.filtN,"filtN/"), `[`, 2)))){
print("List of input files to cutadapt does not match the proposed list of output files.")
print("Quitting.")
quit()
}

# decode arguments for filterAndTrim
all_args <- ""
if ((!is.null(opt$Flength)) & (!is.null(opt$Rlength))){
  length_args <- paste("trimLeft=c(",opt$Flength,",",opt$Rlength,")", sep="")
  all_args <- paste(all_args, length_args, sep=",")
}	

# run filterAndTrim
out <- eval(parse(text = paste("filterAndTrim(fnFs.filtN, fnFs.cut, fnRs.filtN, fnRs.cut, maxN = 0, rm.phix=TRUE, ", all_args, ")")))

# Commands for sending email on completion
email_command <- paste("echo \"Primer removal or sequence trimming is complete.\" | mail -s \"Trimming_complete\", opt$email, sep=" ")
}

system(email_command)
