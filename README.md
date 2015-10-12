# Virtual Normal Correction

This code performs a virtual normal correction on a set of input variants. For more information see our paper in Genome Research [here](http://genome.cshlp.org/content/25/9/1382.abstract)

This analysis can be run on both small variants (i.e. single nucleotide variants and indels of up to ~50 bps) and the larger structural variations (SVs)

For any questions, please contact Saskia Hiltemann (s.hiltemann@erasmusmc.nl)

## Example

There is an example run using just 3 normals (chr21 only) and input from HCC1187 (chr21 only) available in the folder "example". See the README document in the example folder for more information about running the example data.


## How to Run

### Preliminaries

**Reference Genome**
Download the reference genome (.crr file) of the desired build (hg18=build36, hg19=build37) from Complete Genomics: [ftp://ftp.completegenomics.com/ReferenceFiles/](ftp://ftp.completegenomics.com/ReferenceFiles/). 

**CGATools binary**
The cgatools binary version 1.8 is included in this repository under bin/cgatools18, alternatively it may be obtained from [cgatools.sourceforge.net](cgatools.sourceforge.net).

Make sure the cgatools binary is available on your PATH. For example do something like:

The program expects a binary called *cgatools18* to be present on the PATH. To change the expected name of this binary, edit the *cgatools* variable at the top of the scripts: 

```
#!/bin/bash

### location of cgatools binary, change as needed, binaries may be downloaded from Complete Genomics website here: http://cgatools.sourceforge.net/
# latest version as of the writing of this code is included in this repository (v1.8)
cgatools="cgatools18"
```

**Normal Samples**
Configure your Virtual Normal set (see section *Virtual Normal Sets* below)


### Small Variants

Running the VN correction on small variant data:

```bash
$ bash virtual-normal-correction-smallvariants.sh \
    --variants <input list of variants> \
    --reference <reference .crr file> \
    --VN_varfiles_list <list with paths to CG-sequenced normals, one file per line> \
    --threshold <filter out variants appearing in at least this many normals> \
    --threshold_highconf <only output variants fully called in at least this many normals> \
    --outputfile_all <where to store final output> \
    --outputfile_filtered <where to store final output filtered for the two threshold values> \
```

### Structural Variations

Running the VN correction on small variant data:

```bash
$ bash virtual-normal-correction-SVs.sh \
          --variants <CG junctions file> \
          --reference <reference .crr file> \
          --VN_junctionfiles_list <list with paths to CG-sequenced normals, one file per line> \
          --output_prefix <where to store final output, for example output/mysample>         
```

Optionally the following additional parameters may also be given, if any of these parameters are not specified, the default values are used:

```bash
--scoreThresholdA <default 10. The minimum number of discordant mate pair alignments supporting the junction from input genome> 
--scoreThresholdB <default 10. The minimum number of discordant mate pair alignments supporting the junction from normal genoes> 
--distance <default 200. Maximum distance between coordinates of potentially compatible junctions.>
--minlength <default 500. Minimum deletion junctions length to be included into the difference file>
```

## Input format

### Small Variants

The input format may be obtained from a CG varfile by running the CGAtools ListVariants tool, or may be obtained from a VCF file by running the conversion script included in this repository (VCF-2-Variantlist.sh).

Example of VCF conversion:

```
$ bash VCF-2- Variantlist.sh <VCF file> <output variantlist>
```

Example CG varfile conversion:

```
cgatools18 listvariants --beta --variants <varfile> --reference <reference crr file> 
```

The input format must be a tab-delimited file with the following header line:

```
variantId - chromosome - begin - end - varType - reference - alleleSeq - xRef
```

**variantID** - may be any unique identifier  
**chromosome** - must have a *chr* prefix  
**begin** - starting cooridinate in 0-based half-open format  
**end** - end coordinate of the variant in 0-based half-open format  
**varType** - must be one of the following values: snp,ins,del,sub  
**reference** - nucleotide sequence of reference genome at given locus  
**alleleSeq** - observed nucleotide sequence in sample at given locus  
**xRef** - is not used by this program but may contain any annotations you wish or may be left blank or omitted altogether  

Example:

```
variantId       chromosome      begin   end     varType reference       alleleSeq       xRef
1               chr1            38231   38232   snp     A               G               dbsnp.86:rs806727;dbsnp.131:rs77823476
2               chr1            46669   46670   snp     A               G               dbsnp.100:rs2548905
3               chr1            47107   47108   snp     G               C               dbsnp.100:rs2531241
4               chr1            47291   47292   snp     T               G               dbsnp.100:rs2691275
5               chr1            49271   49272   snp     G               A               dbsnp.100:rs2531245
6               chr1            49290   49291   snp     C               T               dbsnp.130:rs71240757
7               chr1            49313   49315   sub     GT              AC                
... 
```

### Structural Variations

For the SV analysis, input must be a Complete Genomics junctions file.


## Output format

### Small Variants

There are 3 output files for the small variant analysis:

1. The main output file  
   containing all variants found in the sample, annotated with the frequency in the normal sets.
2. The filtered output file  
   same format as 1 but all variants which occur in more than the specified number of normals were removed, as well as all variant which were no-called or half-called in more than the specified number of normals
3. The expanded file  
   This is the input file with a column added per normal genome specifying the genotype (00 for not present, 01 for heterozygous, 11 for homozygous, NN for no-called, etc)


*Example of main output file:*

```
variantId chromosome begin   end     varType reference alleleSeq xRef                  VN_occurrences VN_frequency VN_fullycalled_count VN_fullycalled_frequency VN_00 VN_01 VN_11 VN_0N VN_1N VN_NN VN_0 VN_1 VN_N
3155150   chr21      9412628 9412629 snp     C         T         dbsnp.130:rs71220886  1              0.333333     1                    0.333333                 1     0     0     0     1     1     0    0    0
[..]
```

Description of the columns added:

**VN_occurrences** - Number of normals this variants was present in  
**VN_frequency** - Fraction of normals this variant was present in   
**VN_fullycalled_count** - Number of normals that were fully-called at this locus  
**VN_fullycalled_frequency** - Franction of normals that were fully-called at this locus  
**VN_00** - Number of normals without the variant and fully called at the locus.  
**VN_01** - Number of normals with heterozygous occurrence of the variant.  
**VN_11** - Number of normals with homozygous occurrence of the variant.  
**VN_0N** - Number of normals without variant but half-called at the locus.  
**VN_1N** - Number of normals with the variant, but half-called at the locus.  
**VN_NN** - Number of normals without the variant, but nocalled at the locus.  
**VN_0** - Number of normals without the variant, but with only one allele present (e.g. X and Y chromosomes).  
**VN_1** - Number of normals with the variant, but with only one allele present (e.g. X and Y chromosomes).  
**VN_N** - Number of normals without the variant, but no-called at the locus with only one allele present (e.g. X and Y chromosomes).  


*Example of expanded output file:*

```
variantId chromosome begin   end     varType reference alleleSeq xRef                 NA06985-200-37-ASM NA06994-200-37-ASM     NA07357-200-37-ASM
3155150   chr21      9412628 9412629 snp     C         T         dbsnp.130:rs71220886 00                 NN                     1N
[..]
```


### Structural Variations

There are two output files for the SV analysis:

1. Filtered Junctions  
2. Report  

The output junctions are the same format as the input; CG junctions file, but with SVs that were present in one or more of the normals removed.

The report tells you how many variants were removed at each step. 

*Example Report*

```
report of run 1:
----------------------
#GENERATED_BY	cgatools
#GENERATED_AT	2015-Oct-12 16:06:03.542623
#CGATOOLS_VERSION	1.8.0
#FORMAT_VERSION	2.4
#TYPE	JUNCTIONDIFF_REPORT

>fileId	inputJunctions	filteredJunctions	incompatible	filteredIncompatible	compatible	scoreThreshold	maxDistance	minDelLength
65	1581	1581	746	621	835	10	200	500
66	5376	2426	1590	0	836	10	200	500

report of run 2:
----------------------
#GENERATED_BY	cgatools
#GENERATED_AT	2015-Oct-12 16:06:03.597889
#CGATOOLS_VERSION	1.8.0
#FORMAT_VERSION	2.4
#TYPE	JUNCTIONDIFF_REPORT

>fileId	inputJunctions	filteredJunctions	incompatible	filteredIncompatible	compatible	scoreThreshold	maxDistance	minDelLength
65	621	621	504	504	117	10	200	500
66	6489	2163	2047	0	116	10	200	500

report of run 3:
----------------------
#GENERATED_BY	cgatools
#GENERATED_AT	2015-Oct-12 16:06:03.655524
#CGATOOLS_VERSION	1.8.0
#FORMAT_VERSION	2.4
#TYPE	JUNCTIONDIFF_REPORT

>fileId	inputJunctions	filteredJunctions	incompatible	filteredIncompatible	compatible	scoreThreshold	maxDistance	minDelLength
65	504	504	447	447	57	10	200	500
66	4883	2088	2031	0	57	10	200	500
```

for each normal genome, the first line indicates the current set of junctions, and the second line indicates the normal junctionsfile. So in this example, in the first run we started with 1581 input junctions, we compared this to a normal containing 5376 junctions, and were left with 621 junctions after correction.


## Virtual Normal Sets

### How to specify

Download all CG varfiles you wish to use as a virtual normal. Create a text file with their locations, one per line. For instance, for the example data this text file looks like

```
normals/smallvariants/var-NA06985-200-37-ASM_chr21.tsv
normals/smallvariants/var-NA06994-200-37-ASM_chr21.tsv
normals/smallvariants/var-NA07357-200-37-ASM_chr21.tsv
```

Be careful not to have any empty lines in your file.


### Where to download

#### 1000 Genomes Project Data
The set of CG-sequenced normals used in the paper may be downloaded from the 1000 Genomes Project site. Only for build hg19.

Here is a list of all the locations of the CG normals on the 1000Genomes site:

ftp://ftp.1000genomes.ebi.ac.uk/vol1/ftp/complete_genomics_indices/20130725.cg_data.untar.index

(just download all files starting with "var-" (and for SVs download everything starting with "allJunctions") )

NOTE: it seems they have recently moved the files, and not yet updated the list, and you should now put "phase3" before all locations it seems, so if the file says:
data/NA12812/cg_data/ASM_lcl/var-GS000016405-ASM.tsv.bz2
the address now is:
ftp://ftp.1000genomes.ebi.ac.uk/vol1/ftp/phase3/data/NA12812/cg_data/ASM_lcl/var-GS000016405-ASM.tsv.bz2
etc.

#### Complete Genomics Diversity Panel
A smaller set of normals, has some overlap with the set of normals in 1000 Genomes Project, but also available on build hg18. This data may be downloaded from the Complete Genomics FTP server: [ftp://ftp2.completegenomics.com/Diversity/](ftp://ftp2.completegenomics.com/Diversity/)

### Complete Genomics Trios
The parents from the trios available from Complete Genomics may also be used in the virtual normal and can be obtained from the Complete Genomics FTP server: [ftp://ftp2.completegenomics.com/YRI_trio](ftp://ftp2.completegenomics.com/YRI_trio/) and
[ftp://ftp2.completegenomics.com/PUR_trio/](ftp://ftp2.completegenomics.com/PUR_trio/)

Be careful not to include the child, as this will skew the frequencies of occurrence of variants within the population; you should only ever use unrelated individuals.






