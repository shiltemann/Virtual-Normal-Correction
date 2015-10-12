#!/bin/bash

### location of cgatools binary, change as needed, binaries may be downloaded from Complete Genomics website here: http://cgatools.sourceforge.net/
# latest version as of the writing of this code is included in this repository (v1.8)
cgatools="cgatools18"


### if invalid options were given, print usage instructions
function usage(){
  echo ""
  echo "Usage: $0 "
  echo " --variants <input list of variants> "
  echo " --reference <reference .crr file> "
  echo " --VN_varfiles_list <list with paths to CG-sequenced normals, one file per line> "
  echo " --threshold <filter out variants appearing in at least this many normals> "
  echo " --threshold_highconf <only output variants fully called in at least this many normals>"
  echo " --output_prefix <where to store final output, for example output/mysample> "  
  exit
}

### parse input parameters
set -- `getopt -n$0 -u -a --longoptions="variants: reference: VN_varfiles_list: output_prefix: threshold: threshold_highconf: " "h:" "$@"` || usage
[ $# -eq 0 ] && usage

while [ $# -gt 0 ]
do 
    case "$1" in
       --variants)            variants=$2;shift;;
       --reference)           crr=$2;shift;;
       --VN_varfiles_list)    VN_varfiles_list=$2;shift;; 
       --output_prefix)       output_filtered="$2_filtered.tsv"; output_all="$2_main.tsv"; output_expanded="$2_expanded.tsv"; output_prefix=$2; shift;;  
       --threshold)           threshold=$2;shift;; 
       --threshold_highconf)  thresholdhc=$2;shift;;
       -h)                    shift;;
       --)                    shift;break;;
       -*)                    usage;;
       *)                     break;;            
    esac
    shift
done

### check that we have all necessary information
if [[ $variants == "" || $crr == "" || $VN_varfiles_list == "" || $output_prefix == "" || $threshold == "" || $thresholdhc == "" ]]
then
  echo "A mandatory parameter was missing, make sure you provided all required parameters"
  echo " variants: $variants"
  echo " reference: $crr"
  echo " VN_varfiles_list: $VN_varfiles_list"
  echo " output_prefix: $output_prefix"
  echo " threshold: $threshold"
  echo " threshold_highconf: $thresholdhc"
  usage
fi



### enough parameters were given, print settings to stdout so users can doublecheck
echo "********************************************************"
echo "*            Virtual Normal Correction                 *"
echo "********************************************************"
echo ""
echo " Input file:           $variants"
echo " Reference file:       $crr"
echo " Normals list:         $VN_varfiles_list"
echo " Threshold:            $threshold"
echo " HighConf Threshold:   $thresholdhc"
echo " Main Output file:     $output_all"
echo " Filtered Output file: $output_filtered"
echo " Expanded Output file: $output_expanded"
echo " CGAtools binary:      $cgatools"
echo ""
echo " Input must be tab-delimited file with the following headerline :"
echo " < variantId - chromosome - start - end - varType - reference - alelleseq - xRef >"
echo ""
echo " If you have a large number of normals and/or a large number of input variants, this may take quite a long time"
echo ""



### In the list of normals, replace newlines with spaces for input to testvariants
tr '\n' ' ' < $VN_varfiles_list > VN_varfiles.txt
VNsetsize=`cat $VN_varfiles_list | wc -l`

echo "--> Number of normals found: $VNsetsize"


### Run TestVariants against the given virtual normal set
echo "--> Running correction against Virtual Normal set"
$cgatools testvariants \
	--beta \
	--reference $crr \
	--input	$variants \
	--output $output_expanded \
	--variants `cat VN_varfiles.txt`


### Filter file based on occurrence in background genomes


# condens file to columns with counts for all background genomes 
awk 'BEGIN{
		FS="\t";
		OFS="\t";
		totalnormals="'"$VNsetsize"'"+0
		count["00"]="0";
		count["01"]="0";
		count["11"]="0";
		count["0N"]="0";
		count["1N"]="0";		
		count["NN"]="0";
		count["0"]="0";
		count["1"]="0";
		count["N"]="0";
	}{
		if(FNR==1)  # header
			print $1,$2,$3,$4,$5,$6,$7,$8,"VN_occurrences","VN_frequency","VN_fullycalled_count","VN_fullycalled_frequency","VN_00","VN_01","VN_11","VN_0N","VN_1N","VN_NN","VN_0","VN_1","VN_N"
		else{ 
			#count entries in reference genomes
			for (c in count)
				count[c]=0;
			for (i=9; i<=NF; i++){
				count[$i]++;
			}
			occurrences=count["11"]+count["01"]+count["1N"]+count["1"]
			fullycalled=count["11"]+count["01"]+count["00"]+count["1"]+count["0"]
			print $1,$2,$3,$4,$5,$6,$7,$8,occurrences,occurrences/totalnormals,fullycalled,fullycalled/totalnormals,count["00"],count["01"],count["11"],count["0N"],count["1N"],count["NN"],count["0"],count["1"],count["N"]
		}
	}END{


	}' $output_expanded > $output_all



### filter out variants occurring in more than <threshold> of the background genomes, and variants which are no-called or half-called in more than <threshold_highconf> normals.
# if total of columns containing a 1 (01,11,1N,1) is >= threshold
echo "--> Filtering output variants based on given thresholds. (To use different thresholds, filter the main output file on column VN_occurrences and VN_fully_called_count, no need to run the whole program again)"
awk 'BEGIN{
		FS="\t";
		OFS="\t";		
	}{
		if(FNR==1){
			print $0 			
		}
		if(FNR>1){
			if($9 < "'"$threshold"'"+0 && $11 >= "'"$thresholdhc"'"+0 )
				print $0 			
		}
	}END{}' $output_all > $output_filtered 



### Run finished, tell user where to find result
echo "--> Virtual Normal Correction Completed."
echo "--> Output files created: "
echo "       - Main output file: $output_all "
echo "       - Expanded output file: $output_expanded (per-sample annotation) "
echo "       - Filtered output file: $output_filtered (only variants occurring in fewer than $threshold normals, and fully called in at least $thresholdhc normals) "
echo ""







