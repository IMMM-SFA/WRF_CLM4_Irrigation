[![DOI](https://zenodo.org/badge/200178635.svg)](https://zenodo.org/badge/latestdoi/200178635)

# WRF_CLM4_Irrigation
### 1. WRF_CLM4_Paddy_Irrigation (WRF_CLM4_IRR)
WRF-CLM4 code modifications to incorporate representations of census data based irrigation application, groundwater pumping and paddy fields for Kharif season from June-September
### 2. WRF_CLM4_Ideal_Irrigation (WRF_CLM4_IDL)
WRF-CLM4 code modifications to incorporate representations of idealized irrigation based on soil mositure deficit and groundwater pumping for Kharif season from June-September


Repository to distribute Fortran codes developed to incorporate irrigation, groundwater pumping and paddy fields in South Asia in WRF-CLM4 (using WRFv3.8.1). The repository also contains scripts to implement the distributed code to run WRF-CLM4 with irrigation representation. The published regional modeling experiments performed using the developed code (Devanand et al., 2019) were run on the now decommissioned Oak Ridge Leadership Computing Facility (OLCF) machine, Titan

The developed codes are based on model versions WRFv3.8.1 and WPSv3.8.1
Downloaded from: http://www2.mmm.ucar.edu/wrf/users/wrfv3.8/updates-3.8.1.html

The developed codes have also been tested on PNNL Institute Computing (PIC) machine, Constance using the following modules and environmental setting:
```
module load precision/i4
module load intel/15.0.1
module load intelmpi/5.0.1.035
module load netcdf/4.4.1.1
export CC=mpicc
export FC=mpiifort
export NETCDF=/share/apps/netcdf/4.4.1.1/intel/15.0.1/
```

## Repository structure

---scripts | ---WRF_CLM4_IRR_codes | ---WRF_CLM4_IDL_codes | ---namelists

## Tutorial to set up WRF_CLM4_IRR & WRF_CLM4_IDL
We provide detailed notes on performing regional simulations using WRF_CLM4_IRR and WRF_CLM4_IDL on any cluster that can run default WRFV3. We assume that the user has selected their domain and preprocessed the chosen boundary and initial conditions for regional simulations using the WRF Preprocessing system (WPS). Sample namelists used for our experiments over South Asia are provided in the _namelists_ folder

_Note1_: The code is developed to work with landuse classes from MODIS land use data distributed with WRF. Please use MODIS landuse data while preprocessing static geographical datasets for your domain.

_Note2_: The tutorial and scripts are for regional simulations using a single model domain. Use of nested WRF domains would require the user to write the irrigation input data into the corresponding _wrfinput_d0*_ files.

### Set user directory paths
```
export BASE_DIR=<directory-of-choice>
export WPS_DIR=<directory-containing-WPS-metgrid-files>
```
### Download script, data, and code repositories
#### Download irrigation code, script and data repository
```
cd $BASE_DIR
git clone git@github.com:IMMM-SFA/WRF_CLM4_Irrigation.git
```
#### Download WRFv3.8.1 code, please check http://www2.mmm.ucar.edu/wrf/users/download/get_source.html for instructions to download the released version. Place the downloaded WRF direcory (named WRFV3) in the BASE_DIR

### Use the downloaded irrigation code to replace default WRFV3 files to add irrigation representation
```
cd $BASE_DIR
cp WRF_CLM4_Irrigation/WRF_CLM4_<IRR/IDL>_codes/module_sf_clm.F WRFV3/phys/
cp WRF_CLM4_Irrigation/WRF_CLM4_<IRR/IDL>_codes/module_physics_init.F WRFV3/phys/
cp WRF_CLM4_Irrigation/WRF_CLM4_<IRR/IDL>_codes/module_surface_driver.F WRFV3/phys/
cp WRF_CLM4_Irrigation/WRF_CLM4_<IRR/IDL>_codes/start_em.F WRFV3/dyn_em/
cp WRF_CLM4_Irrigation/WRF_CLM4_<IRR/IDL>_codes/module_first_rk_step_part1.F WRFV3/dyn_em/
cp WRF_CLM4_Irrigation/WRF_CLM4_<IRR/IDL>_codes/Registry.EM_COMMON WRFV3/Registry/
cp WRF_CLM4_Irrigation/WRF_CLM4_<IRR/IDL>_codes/registry.clm WRFV3/Registry/
```
#### Compile WRFV3
You may use the commands
```
./configure
./compile em_real >& compile.log
```
### Download the Irrigation input datasets from https://dx.doi.org/10.25584/data.2019-08.903/1548406.  
Please refer Huang et al. (2018) for details of the global estimates of irrigation wateruse. Please refer supplementary material of Devanand et al. (2019) for details about how the estimates of Huang et al. (2018) were combined with agricultural census based irrigation estimates over northern India to produce these irrigation input files for the crop season spanning June-September. The irrigation input data from the above link are available for years 1990 to 2014.

_Note_: The irrigation data files contain data for South Asia. User would need to create similar irrigation data files to employ the model for other regions.
```
mkdir -p $BASE_DIR/Irrigation_inputdata
Download data from https://dx.doi.org/10.25584/data.2019-08.903/1548406 to $BASE_DIR/Irrigation_inputdata
```
### Use the Downloaded datasets to provide irrigation inputs for regional simulations
#### Run _real.exe_ to generate initial and boundary conditions for the WRF simulation
You may use the following lines in your job script to run _real.exe_
```
ln -s $WPS_DIR/met_em* .
mpirun -np 16 ./real.exe
```
#### Use the downloaded scripts to write irrigation input data into _wrfinput_d01_ file
```
export year=<year-of-simulation>
cd $BASE_DIR/WRF_CLM4_Irrigation/scripts
./<irr/idl>_input_irrigation_data.sh
cd $BASE_DIR/WRFV3/run
```
_WRFV3/run/wrfinput_d01_ now contains the irrigation input data for simulations using WRF_CLM4_<IRR/IDL>

### Postprocessing model output
_$BASE_DIR/WRF_CLM4_Irrigation/scripts/postprocessing_ contains NCL scripts that may be used to calculate mean daily outputs from the _wrfout_d01*_ files

## Acknowledgment
Balwinder Singh for help with debugging the irrigation implementation  
Ben Yang, Supantha Paul and University of Nebraska-Lincoln for providing original NCL scripts which are modified for use with this implementation and post processing  

The model development, simulations and analysis efforts were funded and supported by: 
+ Ministry of Earth Sciences, Government of India and National Environmental Research Council (UK) through Newton-Bhaba Project (no. MoES/NERC/IA SWR/P2/09/2016-PC-II)
+ U.S. Department of Energy (DOE), Office of Science, as part of research in Multi-Sector Dynamics, Earth and Environmental System Modeling Program
+ National Climate-Computing Research Center which is located within the National Center for Computational Sciences at the Oak Ridge National Laboratory (ORNL) and supported under a Strategic Partnership Project, 2316-T849-08, between DOE and NOAA.
+ Oak Ridge Leadership Computing Facility at ORNL, which is a DOE Office of Science User Facility supported under Contract DE309
AC05-00OR22725.

## Who do I talk to?
    subimal at civil.iitb.ac.in
    maoyi.huang at pnnl.gov
    anjanadevanand at iitb.ac.in
    
Please let us know in case you make any useful modifications.

## Reference:
Devanand, A., Huang, M., Ashfaq, M., Barik, B., & Ghosh, S. (2019). Choice of Irrigation Water Management Practice affects Indian Summer Monsoon Rainfall and its Extremes. Geophysical Research Letters, _[in press]_. https://doi.org/10.1029/2019GL083875
## Additional References:
Huang, Z., Hejazi, M., Li, X., Tang, Q., Vernon, C., Leng, G., et al. (2018). Reconstruction of global gridded monthly sectoral water withdrawals for 1971–2010 and analysis of their spatiotemporal patterns. Hydrology and Earth System Sciences, 22(4), 2117–2133. https://doi.org/10.5194/hess-22-2117-2018

Leng, G., Huang, M., Tang, Q., Gao, H., & Leung, L. R. (2013). Modeling the Effects of Groundwater-Fed Irrigation on Terrestrial Hydrology over the Conterminous United States. Journal of Hydrometeorology, 15(3), 957–972. https://doi.org/10.1175/jhm-d-13-049.1

Oleson KW, et al. (2010) Technical Description of version 4.0 of the Community Land Model (CLM). NCAR Technical Note NCAR/TN-478+STR (National Center for Atmospheric Research, Boulder, CO), 257 pp

## Recommended acknowledgment for using the code or data
Please cite us when using the code or data


