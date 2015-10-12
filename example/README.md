## About Example Data

This example uses only data on chromosome 21 (for both the normals and input data) to keep file sizes small enough for GitHub.

Reference file for this example could not be included in GitHub but can be downloaded form here (738 MB): [ftp://ftp.completegenomics.com/ReferenceFiles/build37.crr](ftp://ftp.completegenomics.com/ReferenceFiles/build37.crr)

Put this file in the folder "reference", make sure it is named build37.crr, and the example code will work.

Input data is from HCC1187 


## How to run

Running this example should be as easy as running the ExampleRun.sh file

```
$ bash ExampleRun_smallvariants.sh
```

for small variants (SNPs and indels/substitution of up to ~50 bp), or 

```
$ bash ExampleRun_SVs.sh
```

for SVs.

Output will appear in directory *output*, sample output can be found in the directory "output/example-output"




