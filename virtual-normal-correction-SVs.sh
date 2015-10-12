#!/bin/bash

### location of cgatools binary, change as needed, binaries may be downloaded from Complete Genomics website here: http://cgatools.sourceforge.net/
# latest version as of the writing of this code is included in this repository (v1.8)
cgatools="cgatools18"


### if invalid options were given, print usage instructions
function usage(){
  echo ""
  echo "Usage: $0 "
  echo " --variants <CG junctions file> "
  echo " --reference <reference .crr file> "
  echo " --VN_junctionfiles_list <list with paths to CG-sequenced normals, one file per line> "
  echo " --scoreThresholdA <default 10. The minimum number of discordant mate pair alignments supporting the junction from input genome> "
  echo " --scoreThresholdB <default 10. The minimum number of discordant mate pair alignments supporting the junction from normal genomes> "
  echo " --distance <default 200. Maximum distance between coordinates of potentially compatible junctions.>"
  echo " --minlength <default 500. Minimum deletion junctions length to be included into the difference file>"
  echo " --output_prefix <where to store final output, for example output/mysample> "  
  exit
}


### set some defaults
distance=200
minlength=500
scoreThresholdA=10
scoreThresholdB=10


### Parse input parameters		
set -- `getopt -n$0 -u -a --longoptions="variants: reference: VN_junctionfiles_list: output_prefix: scoreThresholdA: scoreThresholdB: distance: minlength: " "h:" "$@"` || usage
[ $# -eq 0 ] && usage

while [ $# -gt 0 ]
do
    case "$1" in
        --variants)                variants=$2;shift;;  
        --reference)               crr=$2;shift;; 
        --VN_junctionfiles_list)   VN_junctionfiles_list=$2;shift;;  
        --output_prefix)           output_filtered="$2_filtered.tsv";output_report="$2_report.txt";output_prefix=$2;shift;;  
        --scoreThresholdA)         scoreThresholdA=$2;shift;;  
        --scoreThresholdB)         scoreThresholdB=$2;shift;;  
        --distance)                distance=$2;shift;;  
        --minlength)               minlength=$2;shift;;
        -h)                        shift;;
        --)                        shift;break;;
        -*)                        usage;;
        *)                         break;;            
    esac
    shift
done


### check that we have all necessary information
if [[ $variants == "" || $crr == "" || $VN_junctionfiles_list == "" || $output_prefix == "" ]]
then
  echo "A mandatory parameter was missing, make sure you provided all required parameters"
  echo "  variants: $variants"
  echo "  reference: $crr"
  echo "  VN_junctionfiles_list: $VN_junctionfiles_list"
  echo "  output_prefix: $output_prefix"
  usage
fi

echo "********************************************************"
echo "*            Virtual Normal Correction                 *"
echo "********************************************************"
echo ""
echo "  variants: $variants"
echo "  reference: $crr"
echo "  VN_junctionfiles_list: $VN_junctionfiles_list"
echo "  output_prefix: $output_prefix"
echo "  distance: $distance "
echo "  minlength: $minlength "
echo "  scoreThresholdA: $scoreThresholdA"
echo "  scoreThresholdB: $scoreThresholdB"
echo ""
echo "  NOTE: performing multiple runs in the same directory simultaneously may give problems with the report output file"
echo ""


### make copy of input junctions file, as this file will be altered
outputdir=`dirname $output_prefix`
outputname=`basename $output_prefix`
junctions="${output_prefix}_currentjunctions.tsv"
cp $variants $junctions  


###  run JunctionDiff against all of the VN junctionfiles
echo "--> Running Virtual Normal Correction against each of the VN genomes"
count=0
while read line           
do  
        if [[ $line != "" ]] # catch empty lines
        then
            count=$[$count+1]         
            $cgatools junctiondiff \
                --beta \
                --statout \
                --reference $crr \
                --junctionsA $junctions \
                --junctionsB $line \
                --scoreThresholdA $scoreThresholdA \
                --scoreThresholdB $scoreThresholdB \
                --distance $distance \
                --minlength $minlength 

            # concatenate all reports
            echo -e "report of run $count:\n----------------------" >> $output_report
            cat report.tsv >> $output_report
            rm report.tsv
            echo "" >> $output_report

            # rename output file to junctions file for next iteration	
            rm $junctions
            mv "diff-${outputname}_currentjunctions.tsv" $junctions
       fi
done <  $VN_junctionfiles_list


### cleanup and move
cp $junctions $output_filtered
rm $junctions


### Run finished, tell user where to find result
echo "--> Virtual Normal Correction Completed."
echo "--> Output files created: "
echo "       - Filtered junctions file: $output_filtered "
echo "       - Report file: $output_report  "
echo ""





