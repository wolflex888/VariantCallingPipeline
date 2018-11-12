#!/bin/bash

PICARD=lib/picard.jar
GATK=lib/GenomeAnalysisTK.jar
usage="usage: -a [input reads 1] -b [input reads 2] -r [ref genome file] -o [ouput VCF file] -e reads re-alignment -z if the output VCF file should be gunzipped -V turn on verbose mode -i index your output BAM file -h print usage information and exit"
while getopts :Veziha:b:r:o: option #getopts to determine which commands are used 
do
    case $option in
        V) verbose=1
            ;;
        e) realign=1
            ;;
        z) gunzip=1
            ;;
        i) samindex=1
            ;;
		h) help=1
	    	;;
		a) input1=$OPTARG
	    	;;
		b) input2=$OPTARG
	    	;;
		r) reference=$OPTARG
	    	;;
		o) output=$OPTARG
	    	;;
    esac
done
#echo $verbose, $realign, $gunzip, $samindex, $help, $input1, $input2, $reference, $output #debug purpose

#-------------------program_argument_check--------------------#
if [ "$verbose" = 1 ] #if the option -v is triggered, the value of v will be 1                         
then
echo "verbose mode on"
set -x #turn on the verbose mode in unix
fi
if [ "$help" = 1 ] #if -h is triggered print the following massage
then
    echo "This shell script is developed (very painfully) by Juichang (David) Lu for BIOL7200 course assignment"
    echo $usage
    exit
fi
if [ -z "$input1" ] #if the argument is missing for -a, then print a warning and exit
then
    echo "sequence 1 is required"
    echo $usage
    exit
fi
if [ ! -f "$input1" ]
then
    echo "sequence 1 directory doesn't exist"
    exit
fi
if [ -z "$input2" ] # if the argument is missing for -b, then print a warning and exit
then
    echo "sequence 2 is required"
    echo $usage
    exit
fi
if [ ! -f "$input2" ]
then
    echo "sequence 2 directory doesn't exist"
    exit
fi
if [ -z "$reference" ] # if the reference file is missing, then print a warning and exit
then
    echo "reference name is required"
    echo $usage
    exit
fi
if [ ! -f "$reference" ]
then
    echo "reference directory doesn't exist"
    exit
fi
if [ -z "$output" ] # if ouput file name is missing, then print a warning and exit
then
    echo "output name is required"
    echo $usage
    exit
elif [ -f "$output" ]
then
    read -p " the assigned file already exist, type EXIT to exit the program type REWRITE to rewrite the file, otherwise type in a alternative file name: " output2
fi
if [ "$output2" == "EXIT" ]
then
    echo "process terminated"
    exit
elif [ "$output2" == "REWRITE" ]
then
    echo "REWRITING!!!"
    rm $output
elif [ -n "$output2" ]
then
    output=$output2
fi
#echo $verbose, $realign, $gunzip, $samindex, $help, $input1, $input2, $reference, $output
#-----------------program_real_beef_mapping------------------#

bwa index $reference #index it
bwa mem -R '@RG\tID:identification\tSM:sample\tLB:library\tPL:platform' $reference $input1 $input2 > tmp/lane.sam #mapping reads
####command comment####
#mem is one of the bwa algorithm -R STR read group header line
#input reads must be .fq
#SM=sample being processed
#LB=library
#PL=platform
samtools fixmate -O bam tmp/lane.sam tmp/lane_fixmate.bam #### what is lane_fixmate.bam?
samtools sort -O bam -o tmp/lane_processed.bam -T tmp/lane_temp tmp/lane_fixmate.bam #sort according to coordinate

#-----------------some_extra_step_that_was_not_on_the_samtools--------------#
java -jar $PICARD CreateSequenceDictionary REFERENCE=$reference OUTPUT=${reference::(${#reference}-3)}.dict #create dictionary for the reference file

samtools faidx $reference #index the reference file

samtools index tmp/lane_processed.bam


#------------------program_real_beef_improvement_realignment_section----------------#
if [ "$realign" == 1 ]
then
java -Xmx2g -jar $GATK -T RealignerTargetCreator -R $reference -I tmp/lane_processed.bam -o tmp/lane.intervals --known data/Mills1000G.b38.vcf
java -Xmx4g -jar $GATK -T IndelRealigner -R $reference -I tmp/lane_processed.bam -targetIntervals tmp/lane.intervals -o tmp/lane_processed2.bam
rm tmp/lane_processed.bam
mv tmp/lane_processed2.bam tmp/lane_processed.bam

fi


#-------------program_real_beef_improvement_recalibration_section-------------#


#java -Xmx4g -jar $GATK -T BaseRecalibrator -R $reference.fa -knownSites >bundle/b38/dbsnp_142.b38.vcf -I lane.bam -o lane_recal.table
#java -Xmx2g -jar $GATK -T PrintReads -R $reference.fa -I lane.bam --BSQR lane_recal.table -o lane_recal.bam

#-----------program_real_beef_index_the_realigned_bam_file---------------#
if [ "$samindex" == 1 ]
then

samtools index tmp/lane_processed.bam
fi

#--------------program_real_beef_improvement----------#

#---------------program_real_beef_variant_calling-----------------#

samtools mpileup -ugf $reference tmp/lane_processed.bam|bcftools call -vmO z -o tmp/wolflex.vcf.gz #samtools command calls genotypes and reduce the list of variant and pass it to bcftools call



tabix -p vcf tmp/wolflex.vcf.gz #index it using tabix

bcftools filter -O z -o $output -s LOWQUAL -i '%QUAL>10' tmp/wolflex.vcf.gz #filter the final file

#----------------last_but_not_least_unzip_the_file-----------#
if [ "$gunzip" != 1 ]
then

gunzip $output

fi

#hope it works
#David Lu Oct 19th, 2016 1:43AM







set +vx
