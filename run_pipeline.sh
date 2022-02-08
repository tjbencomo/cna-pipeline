#!/bin/bash
#SBATCH --job-name=
#SBATCH --output=
#SBATCH --nodes=1
#SBATCH --time=
#SBATCH --cpus-per-task=1
#SBATCH --mem=
#SBATCH --mail-type=END,FAIL
#SBATCH --mail-user=


set -e
cd $(pwd) #Must be run from snakemake directory
snakemake --cluster-config cluster.wes.json -j 499 \
    --use-singularity \
    --cluster 'sbatch -p {cluster.partition} -t {cluster.time} --mem {cluster.mem} -c {cluster.ncpus} -o {cluster.out}'
