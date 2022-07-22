#!/bin/bash
#SBATCH --job-name=<NAME OF JOB>                        # Job name
#SBATCH --mail-type=ALL                                 # Mail events (NONE, BEGIN, END, FAIL, ALL)
#SBATCH --mail-user=<YOUR EMAIL ADDRESS>              	# Where to send mail
#SBATCH --nodes=1                                       # Numbers of nodes
#SBATCH --ntasks=4                                      # Number of CPU (tasks)
#SBATCH --time=00:10:00                                 # Time limit hrs:min:sec
#SBATCH --partition=short                               # Partition/queue requested on server    
#SBATCH --mem=10gb                                      # Memory limit
#SBATCH --output=/YOUR/EOFILES/PATH/%x_%j.out
#SBATCH --error=/YOUR/EOFILES/PATH/%x_%j.err

################ RUNNING SCRIPT IN TERMINAL ##############################################

# Just copy and paste this command in the same directory where sbatch script is located.
# sbatch --export=FILENAME=chr21Eric_repA.RNA d5_fastq_to_bam.sbatch

################ SET REQUIRED VARIABLES ##################################################

INDIR=/PATH/TO/FASTQ/FILES/IN/YOUR/SCRATCH/DIRECTORY
BAM=/PATH/TO/BAM/OUTPUT/DIRECTORY
SAM=/PATH/TO/SAM/OUTPUT/DIRECTORY
QC=/PATH/TO/HISAT2/QC/
INDICES=/scratch/Shares/public/genomes/hisatfiles/hg38/HISAT2/genome

##########################################################################################
############### LOAD REQUIRED MODULES ####################################################

module load hisat2/2.1.0
module load samtools/1.8

##########################################################################################
################## PRINT JOB INFO ########################################################

printf "\nfastq Directory: $INDIR"
printf "\nOutput Directory: $OUTDIR"
printf "\nRun on: $(hostname)"
printf "\nRun from: $(pwd)"
printf "\nScript: $0\n"
date

printf "\nYou've requested $SLURM_CPUS_ON_NODE core(s).\n"

##########################################################################################
################## RUN JOB ###############################################################

# Mapping paired-end FASTQ files to make a SAM file.
hisat2 \
	--threads 4 \
	--very-sensitive \
	-x ${INDICES} \
	-1 ${INDIR}/${FILENAME}.end1.fastq \
	-2 ${INDIR}/${FILENAME}.end2.fastq \
	--new-summary \
	> ${SAM}/${FILENAME}.sam \
	2> ${QC}/${FILENAME}.hisat2_mapstats.txt
        
# Converting SAM to BAM.                               
samtools \
	view -@ 4 -h -bS \
	-o ${BAM}/${FILENAME}.bam \
	${SAM}/${FILENAME}.sam

# Sorting BAM file.         
samtools \
	sort -@ 4 \
	${BAM}/${FILENAME}.bam \
	> ${BAM}/${FILENAME}.sorted.bam

# Removing unsorted BAM file.
rm ${BAM}/${FILENAME}.bam
    
# Indexing sorted BAM file.                          
samtools \
	index \
	${BAM}/${FILENAME}.sorted.bam \
	${BAM}/${FILENAME}.sorted.bam.bai
                                                                        
echo Job finished at `date +"%T %a %d %b %Y"`
