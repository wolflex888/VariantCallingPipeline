SNP-Calling pipeline

Instruction:

**Necessary tools: bwa, samtools, Picard and GATK.

The pipe script utilize the following command:

-a input reads path. The file type should be FASTQ file.

-b input reads path. The file type should be FASTQ file.

-r input reference genome path. The file type should be FASTA file.

-o the path of the output VCF file. The extension should be vcf.gz

-e Re-alignment option

-z unzip the output file

-v verbose mode (print every command to tell the user what the script is doing

-i index your output BAM file

-h print usage information and exit

Structure pipeline directories:

week7/
|------ week7.sh
	|------ README.txt
	|------ data/ #all data file should be in this directory
		|------ D2-DS3_paired1.fq
		|------ D2-DS3_paired2.fq
		|------ chr17.fa
		|------ Mills1000G.b38.vcf
	|------ lib/ #all relavent program file should be in this file
		|------ GenomeAnalysisTK.jar
		|------ picard.jar
	|------ tmp/ # the place where temp file lives
	|------ output/ # final result
		|------ output.vcf.gz

Results:
The final results are the difference of the input reads when they are compared with the reference genome.
The input reads were first mapped to the reference genome. 
The realignment can reduce the number of miscalls of INDELs in the data.
After mapping the file to the reference, the reads are compared to the reference for variants. The result is then filtered with certain QUAL score threshold.
The result generated represent a mutation on the genome compared to the reference. It has the potential of causing genetic disease.
		
