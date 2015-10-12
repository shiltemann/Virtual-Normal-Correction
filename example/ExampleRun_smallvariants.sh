#!/bin/bash

# put cgatools18 binary from this repository on the PATH
export PATH=$PATH:bin/

bash ../virtual-normal-correction-smallvariants.sh \
          --variants input/CG_HCC1187_hg19_variantlist_chr21.tsv \
          --reference reference/build37.crr \
          --VN_varfiles VN_list_smallvariants.txt \
          --threshold 1 \
          --threshold_highconf 3 \
          --output_prefix output/HCC1187example
