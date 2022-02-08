# cna-pipeline
Snakemake workflow to analyze somatic copy number alterations from whole exome data using
[Sequenza](https://cran.r-project.org/web/packages/sequenza/vignettes/sequenza.html) and
[CNVkit](https://cnvkit.readthedocs.io/en/stable/)

## Installation
1. Install [Snakemake](https://snakemake.readthedocs.io/en/stable/)
2. Install singularity or all dependencies (see Dependencies section)
3. Clone repository
4. Create `samples.csv` file with sample information (see Samples File Format section)
5. Modify `config.yaml`
6. If using a SLURM cluster for execution, edit `cluster.json` and `run_pipeline.sh`

## Sample File Format
`samples.csv` should be a CSV file with the following columns:

* patient - patient identifier
* sample_type - either `normal` or `tumor`
* bam - filepath for BAM for that sample

All patients are required to have both normal and tumor BAMs.

### Dependencies
Singularity is recommended to ensure reproducibility and avoid having to manually
manage installation of Sequenza, CNVkit, and R. If you would prefer to not use
Singularity, make sure the following programs are installed and accessible from
your command line:

* `sequenza-utils` command line tool
* CNVkit
* R

The following R libraries are also needed:

* `sequenza`
* `readr`

## Running
**NOTE:** This workflow saves all intermediate and output files to the same
directory where `Snakefile` is located. Ensure you have the appropriate storage
before running

If running locally
```
snakemake -j [# of cores] [--use-singularity]
```

If running on a SLURM cluster (after completing `cluster.json` and `run_pipeline.sh`
```
# This needs to be run from the directory where Snakefile is located
sbatch run_pipeline.sh
```

