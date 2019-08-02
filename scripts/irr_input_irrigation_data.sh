#!/bin/bash

cd $BASE_DIR/WRFV3/run

#------------ Get data and scripts -------------------------------

cp $BASE_DIR/Irrigation_inputdata/irrigation_input*${year}* .
cp $BASE_DIR/WRF_CLM4_Irrigation/scripts/IRR/* .

#------------- Run scripts to input irrigation data ---------------

ncl write_areafrac_irr.ncl
ncl write_othervar_irr.ncl

matlab -nodisplay -nosplash <fsum_area_frac_corr_irr.m> matlab.log 


