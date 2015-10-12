#!/bin/bash

# put cgatools18 binary on path
export PATH=$PATH:bin/

bash ../virtual-normal-correction-SVs.sh \
          --variants input/highConfidenceJunctionsBeta-HCC1187-H-200-37-ASM-T1.tsv \
          --reference reference/build37.crr \
          --VN_junctionfiles_list VN_list_junctions.txt \
          --output_prefix output/HCC1187_junctions_example