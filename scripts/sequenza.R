Sys.setenv("TZDIR"=paste0(Sys.getenv("CONDA_PREFIX"), "/share/zoneinfo"))

library(sequenza)

fp <- snakemake@input[[1]]
data <- sequenza.extract(fp)
CP <- sequenza.fit(data)
idx <- gregexpr('\\.', snakemake@input[[1]])[[1]][1]
sid = substr(basename(snakemake@input[[1]]), 1, idx-1)
print(paste("SampleID:", sid))
print(paste("Output dir:", snakemake@output[["outdir"]]))
sequenza.results(sequenza.extract = data, cp.table = CP, 
                 sample.id = sid, out.dir = snakemake@output[[1]])

