#!/bin/bash

vcffile=$1
outputfile=$2

# vcf columns: CHROM-POS-ID-REF-ALT
# LV cloumns: variantId-chromosome-start-end-reference-alleleSeq-xRef 


# add chr prefix if not present
# determine varType (snp, ins, del, sub)
# convert coordinates to 0-based halfopen
# calculate end coordinate from position and length
# remove leading reference base from the non-SNP variants, update position

awk 'BEGIN{
		FS="\t";
		OFS="\t";	
		count=0;
		
		#output new header
		print "variantId", "chromosome", "begin", "end", "varType", "reference", "alleleSeq", "xRef" > "headerline.txt"
	}{

		if(substr($0,1,1)!="#" && $5 != "."){ #skip header or nonvariant entries (period in ALT column)
						
			# detect multivariants
			chrom=$1
			pos=$2
			ref=$4
			#alt=$5
			reflen=length($4)	
			
			# excel adds quotes sometimes :s
			gsub(/"/,"",ref)
			gsub(/"/,"",alt)
			
			# add chr prefix if needed
			if(substr($1,1,3)!="chr")
				chromosome="chr"$1
			else
				chromosome=chrom
			
			# split ALT column in case of multiple variant alleles
			split($5,alleles,",");
		
			for (i in alleles) {
				alt=alleles[i]
							
				
				# determine varType
				if(length(ref) == 1 && length(alt) == 1)
					varType="snp"
				else if (length(ref) == 1 && substr(ref,1,1)==substr(alt,1,1) )
					varType="ins"
				else if (length(alt) == 1 && substr(ref,1,1)==substr(alt,1,1) )
					varType="del"
				else 
					varType="sub"
					
				# determine start and end coordinates in 0-based half-open coordinate system
					
				if (varType=="snp"){
					start=pos-1
					end=pos			
				}
				else if (varType=="ins"){
					start=pos
					end=pos
				}
				else if (varType=="del"){
					start=pos
					end=pos+(reflen-1)			
				}
				else if (varType=="sub"){
					start=pos-1
					end=pos+(reflen-1)			
				}		
	
				# remove leading reference base
			   	if ( varType!="snp" && substr(ref,1,1)==substr(alt,1,1) ){ #subs not mandatory leading reference base :s
					reference=substr(ref,2)	
					alleleSeq=substr(alt,2)	
					if (varType =="sub"){
					   start+=1
                                        }
				}
				else{
					reference=ref
					alleleSeq=alt
				}
		
				#print output variant(s)
		
				if(chromosome == "chr1" || chromosome == "chr2" || chromosome == "chr3" || chromosome == "chr4" || chromosome == "chr5" || chromosome == "chr6" || chromosome == "chr7" || chromosome == "chr8" || chromosome == "chr9" || chromosome == "chr10" || chromosome == "chr11" || chromosome == "chr12" || chromosome == "chr13" || chromosome == "chr14" || chromosome == "chr15" || chromosome == "chr16" || chromosome == "chr17" ||chromosome == "chr18" ||chromosome == "chr19" ||chromosome == "chr20" ||chromosome == "chr21" ||chromosome == "chr22" ||chromosome == "chrX" ||chromosome == "chrY" )
					print count, chromosome, start, end, varType, reference, alleleSeq, ""
			
				count+=1
			}
		}
	}END{}' $vcffile > $outputfile
	
	

# due to overlapping variants that we reduce to more canonical forms, variants may have become out of order, so resort to be sure
sort -k2,2V -k3,3g $outputfile > $outputfile.sorted

cat headerline.txt $outputfile.sorted > $outputfile

rm $outputfile.sorted headerline.txt