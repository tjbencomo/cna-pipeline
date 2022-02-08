Sys.setenv("TZDIR"=paste0(Sys.getenv("CONDA_PREFIX"), "/share/zoneinfo"))
library(readr)

files <- snakemake@input

dfs <- list()
for (i in 1:length(files)) {
    fp <- files[[i]]
    idx <- gregexpr('\\.', fp)[[1]][1]
    sid <- basename(substr(fp, 1, idx-1))
    df <- read_tsv(fp)
    df$sample_id <- sid
    df <- df[2, ] #only get point estimate
    dfs[[i]] <- df
}

df <- do.call("rbind", dfs)

print(df)
print(summary(df))

write_csv(df, snakemake@output[[1]])
