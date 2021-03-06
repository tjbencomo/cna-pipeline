import os
import pandas as pd

# Check that each patient has 2 bams (normal + tumor)
def check_samples(df):
    res = df.groupby('patient').size()
    passCountCheck = res.loc[res != 2].shape[0] == 0
    L = ['normal', 'tumor']
    s = set(L)
    out = df.groupby('patient')['sample_type'].apply(lambda x: s.issubset(x))
    passSampleCheck = out.sum() == out.shape[0]
    return passCountCheck and passSampleCheck

CHROMOSOMES = ['chr' + str(i) for i in range(1, 22)] + ['chrX', 'chrY']

configfile: 'config.yaml'

# Sample Info
samples = pd.read_csv(config['samples'])
if not check_samples(samples):
    raise ValueError("Your samples CSV is not right! Make sure each patient has a normal and tumor bam")
samples = samples.set_index(['patient', 'sample_type'], drop = False)

## Reference Files
ref_fasta = config['ref_fasta']

## Target Capture Region File
regions = config['capture_regions']

# Logs
slurm_logdir = config['slurm_log_dir']
logpath = Path(slurm_logdir)
logpath.mkdir(parents=True, exist_ok=True) 

## CNVKit threads
cnvkit_threads = config['cnvkit_threads']

## Containers
sequenza_env = config['sequenza_env']
cnvkit_env = config['cnvkit_env']

def get_bams(wildcards):
    return {'normal' : samples.loc[(wildcards.patient, 'normal'), 'bam'],
            'tumor' : samples.loc[(wildcards.patient, 'tumor'), 'bam']}

def get_normal_bams():
    return samples.loc[samples['sample_type'] == 'normal', 'bam'].tolist()

def get_tumor_bams():
    return samples.loc[samples['sample_type'] == 'tumor', 'bam'].tolist()

rule targets:
    input:
        "results/sequenza_info.csv",
        "cnvkit-results"

rule make_GC_wiggle:
    input:
        ref_fasta 
    output:
        "hg38.gc50Base.wig.gz"
    singularity: sequenza_env
    shell:
        """
        sequenza-utils gc_wiggle --fasta {input} -w 50 -o {output}
        """

rule process_bam:
    input:
        unpack(get_bams),
        fasta=ref_fasta,
        GC="hg38.gc50Base.wig.gz"
    output:
        seqz="sequenza/{patient}.seqz.gz",
        tbi="sequenza/{patient}.seqz.gz.tbi",
        small="sequenza/{patient}.small.seqz.gz",
        smalltbi="sequenza/{patient}.small.seqz.gz.tbi"
    params:
        chroms='-C ' + ' '.join(CHROMOSOMES)
    singularity: sequenza_env
    shell:
        """
        sequenza-utils bam2seqz -n {input.normal} -t {input.tumor} --fasta {input.fasta} \
            -gc {input.GC} -o {output.seqz} {params.chroms}
        sequenza-utils seqz_binning --seqz {output.seqz} -w 50 -o {output.small}
        """

rule sequenza:
    input:
        seqz="sequenza/{patient}.small.seqz.gz",
        tbi="sequenza/{patient}.small.seqz.gz.tbi"
    output:
        outdir=directory("sequenza/{patient}-results/"),
        estimates="sequenza/{patient}-results/{patient}.small.se_confints_CP.txt"
    singularity: sequenza_env
    script:
        "scripts/sequenza.R"

rule gather_info:
    input:
        expand("sequenza/{patient}-results/{patient}.small.se_confints_CP.txt", patient=samples.patient.unique())
    output:
        "results/sequenza_info.csv"
    singularity: sequenza_env
    script:
        "scripts/gather_info.R"

rule make_access:
    input:
        ref_fasta
    output:
        "access.5kb.hg38.bed"
    singularity: cnvkit_env
    shell:
        """
        cnvkit.py access {input} -o {output}
        """

rule cnvkit:
    input:
        normals=get_normal_bams(),
        tumors=get_tumor_bams(),
        targets=regions,
        ref=ref_fasta,
        access="access.5kb.hg38.bed"
    output:
        directory('cnvkit-results')
    singularity: cnvkit_env
    threads: cnvkit_threads
    shell:
        """
        cnvkit.py batch {input.tumors} --normal {input.normals} \
            --targets {input.targets} --fasta {input.ref} \
            --access {input.access} \
            --output-dir {output} \
            --output-reference cnvkit_reference.cnn \
            -p {threads}
        """
