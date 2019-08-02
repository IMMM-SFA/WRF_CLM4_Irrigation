;---- originally created by UNL, obtained from S. Paul
;---- modified by Anjana in Aug 2018 for WRF-IDL experiments 
;--------------------------------------------------------------------------

;   Example script to create daily averages for an entire month 
;   from a WRF real-data run, with the ARW coordinate dynamics option.
;   Interpolating to mandatory pressure levels.

; Usage:
;     ncl [domain=<domain#>] [month=<month#>] [year=<year#>] WRF_daily.ncl

load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/wrf/WRFUserARW.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/wrf/WRF_contributed.ncl"

begin
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Interpolate to the mandatory pressure levels
    interp_levels = (/ 1000., 925., 850., 700., 600., 500., 400., \
                     300., 250., 200., 150., 100./)
    interp_levels!0 = "pres_lev"
    interp_levels&pres_lev = interp_levels
    interp_levels@units = "hPa"
  nlevs         = dimsizes(interp_levels)   ; number of pressure levels

; get domain, year and month from command line
  if (.not. isvar("domain")) then
    domain = 4
  end if
  if (.not. isvar("year")) then
    year = 2004
  end if
  if (.not. isvar("month")) then
    month = 2
  end if

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; The  absolute path to the WRF ARW input files.  
  data_path = "/lustre/atlas/proj-shared/cli106/anjana/WRF_ideal_runs/WRFV3_mod_jjas_wpaddy_ideal_datec_areafrac_7layers_1989/run/"
  mon = sprinti("%0.2i",month)
  file_tmpl = data_path+"wrfout_d0"+domain+"_"+year+"-" +mon+"-??_00:00:00"
; This needs to have a ".nc" appended, so just do it.
  month_files = systemfunc("/bin/ls "+file_tmpl)+".nc"
  ndays = dimsizes(month_files)

  nxt_year = year
  nxt_month = month + 1
  if (nxt_month .eq. 13) then
    nxt_year = year + 1
    nxt_month = 1
  end if

; get first day of following month; needed for precip
  nxt_mon = sprinti("%0.2i",nxt_month)
  lastfile = data_path+"wrfout_d0"+domain+"_"+nxt_year+"-"+nxt_mon+"-01_00:00:00"
  lastfile = lastfile+".nc"

; concatenate file lists
  files = new(ndays+1,typeof(month_files))
  files(0:ndays-1) = month_files
  files(ndays) = lastfile

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; get static (time-invariant) fields from first day's output
  b = addfile(files(0),"r")
  WRFatt_names = getvaratts(b)    ; get global file attributes

; What is the grid size for this domain?
  xlat = b->XLAT(0,:,:)

  grid_sz  = dimsizes(xlat)
  delete(xlat)

  DZS = b->DZS(0,:)
  soil_layers = dimsizes(DZS)
  subgrid_type = 12

  time = 0
    time!0 = "time"
    time&time = time
    time@units = "YYYYMMDD"
  ntimes = 1

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Define the output variables to hold one time
  XLAT = new((/ntimes, grid_sz(0), grid_sz(1)/), "float")
   XLAT@FieldType = 104
   XLAT@MemoryOrder = "XY "
   XLAT@description = "LATITUDE, SOUTH IS NEGATIVE"
   XLAT@units = "degree_north"
   XLAT@stagger = ""
  XLONG = new((/ntimes, grid_sz(0), grid_sz(1)/), "float")
    XLONG@FieldType = 104
    XLONG@MemoryOrder = "XY "
    XLONG@description = "LONGITUDE, WEST IS NEGATIVE"
    XLONG@units = "degree_east"
    XLONG@stagger = ""
  qirrig   = new((/ntimes, grid_sz(0), grid_sz(1)/), "float")
    qirrig@FieldType=104
    qirrig@MemoryOrder = "XY "
    qirrig@description = "Irrigation water added acc"
    qirrig@units = "mm"
    qirrig@stagger = ""
    qirrig@coordinates = "XLONG XLAT"
wa_colavg  = new((/ntimes, grid_sz(0), grid_sz(1)/), "float")
    wa_colavg@FieldType=104
    wa_colavg@MemoryOrder = "XY "
    wa_colavg@description = "WA colavg"
    wa_colavg@units = "mm"
    wa_colavg@stagger = ""
    wa_colavg@coordinates = "XLONG XLAT"
wt_colavg   = new((/ntimes, grid_sz(0), grid_sz(1)/), "float")
    wt_colavg@FieldType=104
    wt_colavg@MemoryOrder = "XY "
    wt_colavg@description = "WT colavg"
    wt_colavg@units = "mm"
    wt_colavg@stagger = ""
    wt_colavg@coordinates = "XLONG XLAT"
zwt_colavg = new((/ntimes, grid_sz(0), grid_sz(1)/), "float")
    zwt_colavg@FieldType=104
    zwt_colavg@MemoryOrder = "XYZ"
    zwt_colavg@description = "ZWT colavg"
    zwt_colavg@units = "m"
    zwt_colavg@stagger = ""
    zwt_colavg@coordinates = "XLONG XLAT"
area_frac = new((/ntimes, grid_sz(0), grid_sz(1)/), "float")
    area_frac@FieldType=104
    area_frac@MemoryOrder = "XYZ"
    area_frac@description = "fraction of irrigated cropland area"
    area_frac@units = "fraction"
    area_frac@stagger = ""
    area_frac@coordinates = "XLONG XLAT"
  LU_INDEX = new((/ntimes, grid_sz(0), grid_sz(1)/), "float")
    LU_INDEX@FieldType = 104
    LU_INDEX@MemoryOrder = "XY "
    LU_INDEX@description = "LAND USE CATEGORY"
    LU_INDEX@units = ""
    LU_INDEX@stagger = ""
    LU_INDEX@coordinates = "XLONG XLAT"
  LANDMASK = new((/ntimes, grid_sz(0), grid_sz(1)/), "float")
    LANDMASK@FieldType = 104
    LANDMASK@MemoryOrder = "XY "
    LANDMASK@description = "LAND MASK (1 FOR LAND, 0 FOR WATER)"
    LANDMASK@units = ""
    LANDMASK@stagger = ""
    LANDMASK@coordinates = "XLONG XLAT"
  IVGTYP = new((/ntimes, grid_sz(0), grid_sz(1)/), "float")
    IVGTYP@FieldType = 106
    IVGTYP@MemoryOrder = "XY "
    IVGTYP@description = "DOMINANT VEGETATION CATEGORY"
    IVGTYP@units = ""
    IVGTYP@stagger = ""
    IVGTYP@coordinates = "XLONG XLAT"
  ISLTYP = new((/ntimes, grid_sz(0), grid_sz(1)/), "float")
    ISLTYP@FieldType = 106
    ISLTYP@MemoryOrder = "XY "
    ISLTYP@description = "DOMINANT SOIL CATEGORY"
    ISLTYP@units = ""
    ISLTYP@stagger = ""
    ISLTYP@coordinates = "XLONG XLAT"
  VEGFRA = new((/ntimes, grid_sz(0), grid_sz(1)/), "float")
    VEGFRA@FieldType = 104
    VEGFRA@MemoryOrder = "XY "
    VEGFRA@description = "VEGETATION FRACTION"
    VEGFRA@units = ""
    VEGFRA@stagger = ""
    VEGFRA@coordinates = "XLONG XLAT"
  LAI = new((/ntimes, grid_sz(0), grid_sz(1)/), "float")
    LAI@FieldType = 104
    LAI@MemoryOrder = "XY "
    LAI@description = "Leaf area index"
    LAI@units = "area/area"
    LAI@stagger = ""
    LAI@coordinates = "XLONG XLAT"
  HGT = new((/ntimes, grid_sz(0), grid_sz(1)/), "float")
    HGT@FieldType = 104
    HGT@MemoryOrder = "XY "
    HGT@description = "Terrain Height"
    HGT@units = "m"
    HGT@stagger = ""
    HGT@coordinates = "XLONG XLAT"
 canwat = new((/ntimes, grid_sz(0), grid_sz(1)/), "float")
    canwat@FieldType = 104
    canwat@MemoryOrder = "XY "
    canwat@description = "Canopy Water"
    canwat@units = "kg m-2"
    canwat@stagger = ""
    canwat@coordinates = "XLONG XLAT"
 cldfra_plev = new((/ntimes, nlevs, grid_sz(0), grid_sz(1)/), "float")
    cldfra_plev@FieldType=104
    cldfra_plev@MemoryOrder = "XYZ"
    cldfra_plev@description = "Cloud Fraction"
    cldfra_plev@units = ""
    cldfra_plev@stagger = ""
    cldfra_plev@coordinates = "XLONG XLAT"
 glw = new((/ntimes, grid_sz(0), grid_sz(1)/), "float")
    glw@FieldType = 104
    glw@MemoryOrder = "XY "
    glw@description = "Downward Long Wave Flux at Ground Surface"
    glw@units = "W m-2"
    glw@stagger = ""
    glw@coordinates = "XLONG XLAT"
 grdflx = new((/ntimes, grid_sz(0), grid_sz(1)/), "float")
    grdflx@FieldType = 104
    grdflx@MemoryOrder = "XY "
    grdflx@description = "Ground Heat Flux"
    grdflx@units = "W m-2"
    grdflx@stagger = ""
    grdflx@coordinates = "XLONG XLAT"
 lwup = new((/ntimes, grid_sz(0), grid_sz(1)/), "float")
    lwup@FieldType = 104
    lwup@MemoryOrder = "XY "
    lwup@description = "Outgoing Longwave Radiation"
    lwup@units = "W m-2"
    lwup@stagger = "Z"
    lwup@coordinates = "XLONG XLAT"
 olr = new((/ntimes, grid_sz(0), grid_sz(1)/), "float")
    olr@FieldType = 104
    olr@MemoryOrder = "XY "
    olr@description = "Toa Outgoing Longwave Radiation"
    olr@units = "W m-2"
    olr@stagger = ""
    olr@coordinates = "XLONG XLAT"
  sh2o = new((/ntimes, soil_layers, grid_sz(0), grid_sz(1)/), "float")
    sh2o@FieldType = 104
    sh2o@MemoryOrder = "XYZ "
    sh2o@description = "Soil Liquid Water";
    sh2o@units = "m3 m-3"
    sh2o@stagger = "Z"
    sh2o@coordinates = "XLONG XLAT"
  swdown = new((/ntimes, grid_sz(0), grid_sz(1)/), "float")
    swdown@FieldType = 104
    swdown@MemoryOrder = "XY "
    swdown@description = "Downward Short Wave Flux at Ground Surface"
    swdown@units = "W m-2"
    swdown@stagger = ""
    swdown@coordinates = "XLONG XLAT"
  th2 = new((/ntimes, grid_sz(0), grid_sz(1)/), "float")
    th2@FieldType=104
    th2@MemoryOrder = "XY "
    th2@description = " Pot temperature at 2m"
    th2@units = "K"
    th2@stagger = ""
    th2@coordinates = "XLONG XLAT"
  ALBEDO = new((/ntimes, grid_sz(0), grid_sz(1)/), "float")
    ALBEDO@FieldType = 104
    ALBEDO@MemoryOrder = "XY "
    ALBEDO@description = "ALBEDO"
    ALBEDO@units = "-"
    ALBEDO@stagger = ""
    ALBEDO@coordinates = "XLONG XLAT"
  ALBBCK = new((/ntimes, grid_sz(0), grid_sz(1)/), "float")
    ALBBCK@FieldType = 104
    ALBBCK@MemoryOrder = "XY "
    ALBBCK@description = "BACKGROUND ALBEDO"
    ALBBCK@units = ""
    ALBBCK@stagger = ""
    ALBBCK@coordinates = "XLONG XLAT"
  EMISS = new((/ntimes, grid_sz(0), grid_sz(1)/), "float")
    EMISS@FieldType = 104
    EMISS@MemoryOrder = "XY "
    EMISS@description = "SURFACE EMISSIVITY"
    EMISS@units = ""
    EMISS@stagger = ""
    EMISS@coordinates = "XLONG XLAT"
  XLAND = new((/ntimes, grid_sz(0), grid_sz(1)/), "float")
    XLAND@FieldType = 104
    XLAND@MemoryOrder = "XY "
    XLAND@description = "LAND MASK (1 FOR LAND, 2 FOR WATER)"
    XLAND@units = ""
    XLAND@stagger = ""
    XLAND@coordinates = "XLONG XLAT"
 q2     = new((/ntimes, grid_sz(0), grid_sz(1)/), "float")
    q2@FieldType=104
    q2@MemoryOrder = "XY "
    q2@description = " water vapor mixing ratio at 2m"
    q2@units = "kg kg-1"
    q2@stagger = ""
    q2@coordinates = "XLONG XLAT"
 qfx     = new((/ntimes, grid_sz(0), grid_sz(1)/), "float")
    qfx@FieldType=104
    qfx@MemoryOrder = "XY "
    qfx@description = "upward moisture flux at the surface"
    qfx@units = "W m-2"
    qfx@stagger = ""
    qfx@coordinates = "XLONG XLAT" 
  lh     = new((/ntimes, grid_sz(0), grid_sz(1)/), "float")
    lh@FieldType=104
    lh@MemoryOrder = "XY "
    lh@description = "latent heat flux at the surface"
    lh@units = "W m-2"
    lh@stagger = ""
    lh@coordinates = "XLONG XLAT"    
  pblh     = new((/ntimes, grid_sz(0), grid_sz(1)/), "float")
    pblh@FieldType=104
    pblh@MemoryOrder = "XY "
    pblh@description = "pbl height"
    pblh@units = "m"
    pblh@stagger = ""
    pblh@coordinates = "XLONG XLAT"    
  hfx     = new((/ntimes, grid_sz(0), grid_sz(1)/), "float")
    hfx@FieldType=104
    hfx@MemoryOrder = "XY "
    hfx@description = "sensible heat flux at the surface"
    hfx@units = "W m-2"
    hfx@stagger = ""
    hfx@coordinates = "XLONG XLAT"         
  u10    = new((/ntimes, grid_sz(0), grid_sz(1)/), "float")
    u10@FieldType=104
    u10@MemoryOrder = "XY "
    u10@description = "x-wind at 10m"
    u10@units = "m s-1"
    u10@stagger = ""
    u10@coordinates = "XLONG XLAT"
  v10    = new((/ntimes, grid_sz(0), grid_sz(1)/), "float")
    v10@FieldType=104
    v10@MemoryOrder = "XY "
    v10@description = "y-wind at 10m"
    v10@units = "m s-1"
    v10@stagger = ""
    v10@coordinates = "XLONG XLAT"
  t2_min = new((/ntimes, grid_sz(0), grid_sz(1)/), "float")
    t2_min@FieldType=104
    t2_min@MemoryOrder = "XY "
    t2_min@description = "daily minimum temperature at 2m"
    t2_min@units = "K"
    t2_min@stagger = ""
    t2_min@coordinates = "XLONG XLAT"
  t2_max = new((/ntimes, grid_sz(0), grid_sz(1)/), "float")
    t2_max@FieldType=104
    t2_max@MemoryOrder = "XY "
    t2_max@description = "daily maximum temperature at 2m"
    t2_max@units = "K"
    t2_max@stagger = ""
    t2_max@coordinates = "XLONG XLAT"
rainc   = new((/ntimes, grid_sz(0), grid_sz(1)/), "float")
    rainc@FieldType=104
    rainc@MemoryOrder = "XY "
    rainc@description = "DAILY CUMULUS PRECIPITATION"
    rainc@units = "mm"
    rainc@stagger = ""
    rainc@coordinates = "XLONG XLAT"
rainnc   = new((/ntimes, grid_sz(0), grid_sz(1)/), "float")
    rainnc@FieldType=104
    rainnc@MemoryOrder = "XY "
    rainnc@description = "DAILY GRID SCALE PRECIPITATION"
    rainnc@units = "mm"
    rainnc@stagger = ""
    rainnc@coordinates = "XLONG XLAT"
rainsh   = new((/ntimes, grid_sz(0), grid_sz(1)/), "float")
    rainsh@FieldType=104
    rainsh@MemoryOrder = "XY "
    rainsh@description = "DAILY SHALLOW CUMULUS PRECIPITATION"
    rainsh@units = "mm"
    rainsh@stagger = ""
    rainsh@coordinates = "XLONG XLAT"
sfroff   = new((/ntimes, grid_sz(0), grid_sz(1)/), "float")
    sfroff@FieldType=104
    sfroff@MemoryOrder = "XY "
    sfroff@description = "SURFACE RUNOFF"
    sfroff@units = "mm"
    sfroff@stagger = ""
    sfroff@coordinates = "XLONG XLAT"
udroff   = new((/ntimes, grid_sz(0), grid_sz(1)/), "float")
    udroff@FieldType=104
    udroff@MemoryOrder = "XY "
    udroff@description = "UNDERGROUND RUNOFF"
    udroff@units = "mm"
    udroff@stagger = ""
    udroff@coordinates = "XLONG XLAT"
sabg   = new((/ntimes, grid_sz(0), grid_sz(1)/), "float")
    sabg@FieldType=104
    sabg@MemoryOrder = "XY "
    sabg@description = "NET SOIL SOLAR RADIATION"
    sabg@units = "W m-2"
    sabg@stagger = "Z"
    sabg@coordinates = "XLONG XLAT"
sabv   = new((/ntimes, grid_sz(0), grid_sz(1)/), "float")
    sabv@FieldType=104
    sabv@MemoryOrder = "XY "
    sabv@description = "NET VEGETATION SOLAR RADIATION"
    sabv@units = "W m-2"
    sabv@stagger = "Z"
    sabv@coordinates = "XLONG XLAT"
shdmax   = new((/ntimes, grid_sz(0), grid_sz(1)/), "float")
    shdmax@FieldType=104
    shdmax@MemoryOrder = "XY "
    shdmax@description = "ANNUAL MAX VEG FRACTION"
    shdmax@units = ""
    shdmax@stagger = ""
    shdmax@coordinates = "XLONG XLAT"
shdmin   = new((/ntimes, grid_sz(0), grid_sz(1)/), "float")
    shdmin@FieldType=104
    shdmin@MemoryOrder = "XY "
    shdmin@description = "ANNUAL MIN VEG FRACTION"
    shdmin@units = ""
    shdmin@stagger = ""
    shdmin@coordinates = "XLONG XLAT"
snowh   = new((/ntimes, grid_sz(0), grid_sz(1)/), "float")
    snowh@FieldType=104
    snowh@MemoryOrder = "XY "
    snowh@description = "PHYSICAL SNOW DEPTH"
    snowh@units = "m"
    snowh@stagger = ""
    snowh@coordinates = "XLONG XLAT"
seaice   = new((/ntimes, grid_sz(0), grid_sz(1)/), "float")
    seaice@FieldType=104
    seaice@MemoryOrder = "XY "
    seaice@description = "SEA ICE FLAG"
    seaice@units = ""
    seaice@stagger = ""
    seaice@coordinates = "XLONG XLAT"
snownc   = new((/ntimes, grid_sz(0), grid_sz(1)/), "float")
    snownc@FieldType=104
    snownc@MemoryOrder = "XY "
    snownc@description = "DAILY GRID SCALE SNOW AND ICE"
    snownc@units = "mm"
    snownc@stagger = ""
    snownc@coordinates = "XLONG XLAT"
 hailnc   = new((/ntimes, grid_sz(0), grid_sz(1)/), "float")
    hailnc@FieldType=104
    hailnc@MemoryOrder = "XY "
    hailnc@description = "DAILY GRID SCALE HAIL"
    hailnc@units = "mm"
    hailnc@stagger = ""
    hailnc@coordinates = "XLONG XLAT"
  prcp   = new((/ntimes, grid_sz(0), grid_sz(1)/), "float")
    prcp@FieldType=104
    prcp@MemoryOrder = "XY "
    prcp@description = "daily total precipitation"
    prcp@units = "mm"
    prcp@stagger = ""
    prcp@coordinates = "XLONG XLAT"
  snow   = new((/ntimes, grid_sz(0), grid_sz(1)/), "float")
    snow@FieldType=104
    snow@MemoryOrder = "XY "
    snow@description = "snow water equivalent"
    snow@units = "kg m-2"
    snow@stagger = ""
    snow@coordinates = "XLONG XLAT"
  sst   = new((/ntimes, grid_sz(0), grid_sz(1)/), "float")
    sst@FieldType=104
    sst@MemoryOrder = "XY "
    sst@description = "sea surface temperature"
    sst@units = "K"
    sst@stagger = ""
    sst@coordinates = "XLONG XLAT"
psfc   = new((/ntimes, grid_sz(0), grid_sz(1)/), "float")
    psfc@FieldType=104
    psfc@MemoryOrder = "XY "
    psfc@description = "surface pressure"
    psfc@units = "hPa"
    psfc@stagger = ""
    psfc@coordinates = "XLONG XLAT"
  pmsl   = new((/ntimes, grid_sz(0), grid_sz(1)/), "float")
    pmsl@FieldType=104
    pmsl@MemoryOrder = "XY "
    pmsl@description = "pressure at mean sea level"
    pmsl@units = "hPa"
    pmsl@stagger = ""
    pmsl@coordinates = "XLONG XLAT"
  t2     = new((/ntimes, grid_sz(0), grid_sz(1)/), "float")
    t2@FieldType=104
    t2@MemoryOrder = "XY "
    t2@description = "temperature at 2m"
    t2@units = "K"
    t2@stagger = ""
    t2@coordinates = "XLONG XLAT"

;;;;DERIVED VAR;;;;;;;


    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;3D Variables
  t_plev = new((/ntimes, nlevs, grid_sz(0), grid_sz(1)/), "float")
    t_plev@FieldType=104
    t_plev@MemoryOrder = "XYZ"
    t_plev@description = "temperature"
    t_plev@units = "K"
    t_plev@stagger = ""
    t_plev@coordinates = "XLONG XLAT"
  z_plev = new((/ntimes, nlevs, grid_sz(0), grid_sz(1)/), "float")
    z_plev@FieldType=104
    z_plev@MemoryOrder = "XYZ"
    z_plev@description = "geopotential height"
    z_plev@units = "m"
    z_plev@stagger = ""
    z_plev@coordinates = "XLONG XLAT"
  q_plev = new((/ntimes, nlevs, grid_sz(0), grid_sz(1)/), "float")
    q_plev@FieldType=104
    q_plev@MemoryOrder = "XYZ"
    q_plev@description = "water vapor mixing ratio"
    q_plev@units = "kg kg-1"
    q_plev@stagger = ""
    q_plev@coordinates = "XLONG XLAT" 
    
  pb_plev = new((/ntimes, nlevs, grid_sz(0), grid_sz(1)/), "float")
    pb_plev@FieldType=104
    pb_plev@MemoryOrder = "XYZ"
    pb_plev@description = "BASE STATE PRESSURE"
    pb_plev@units = "Pa"
    pb_plev@stagger = ""
    pb_plev@coordinates = "XLONG XLAT" 
 
  qrain_plev = new((/ntimes, nlevs, grid_sz(0), grid_sz(1)/), "float")
    qrain_plev@FieldType=104
    qrain_plev@MemoryOrder = "XYZ"
    qrain_plev@description = "rain water mixing ratio"
    qrain_plev@units = "kg kg-1"
    qrain_plev@stagger = ""
    qrain_plev@coordinates = "XLONG XLAT" 
   
   qsnow_plev = new((/ntimes, nlevs, grid_sz(0), grid_sz(1)/), "float")
    qsnow_plev@FieldType=104
    qsnow_plev@MemoryOrder = "XYZ"
    qsnow_plev@description = "Snow mixing ratio"
    qsnow_plev@units = "kg kg-1"
    qsnow_plev@stagger = ""
    qsnow_plev@coordinates = "XLONG XLAT"    
   
  qcloud_plev = new((/ntimes, nlevs, grid_sz(0), grid_sz(1)/), "float")
    qcloud_plev@FieldType=104
    qcloud_plev@MemoryOrder = "XYZ"
    qcloud_plev@description = "cloud vapor mixing ratio"
    qcloud_plev@units = "kg kg-1"
    qcloud_plev@stagger = ""
    qcloud_plev@coordinates = "XLONG XLAT"    
  qice_plev = new((/ntimes, nlevs, grid_sz(0), grid_sz(1)/), "float")
    qice_plev@FieldType=104
    qice_plev@MemoryOrder = "XYZ"
    qice_plev@description = "ice mixing ratio"
    qice_plev@units = "kg kg-1"
    qice_plev@stagger = ""
    qice_plev@coordinates = "XLONG XLAT"      
  u_plev = new((/ntimes, nlevs, grid_sz(0), grid_sz(1)/), "float")
    u_plev@FieldType=104
    u_plev@MemoryOrder = "XYZ"
    u_plev@description = "x-wind component"
    u_plev@units = "m s-1"
    u_plev@stagger = ""
    u_plev@coordinates = "XLONG XLAT"
  v_plev = new((/ntimes, nlevs, grid_sz(0), grid_sz(1)/), "float")
    v_plev@FieldType=104
    v_plev@MemoryOrder = "XYZ"
    v_plev@description = "y-wind component"
    v_plev@units = "m s-1"
    v_plev@stagger = ""
    v_plev@coordinates = "XLONG XLAT"
  w_plev = new((/ntimes, nlevs, grid_sz(0), grid_sz(1)/), "float")
    w_plev@FieldType=104
    w_plev@MemoryOrder = "XYZ"
    w_plev@description = "w-wind component"
    w_plev@units = "m s-1"
    w_plev@stagger = ""
    w_plev@coordinates = "XLONG XLAT"
tslb   = new((/ntimes, soil_layers, grid_sz(0), grid_sz(1)/), "float")
    tslb@FieldType=104
    tslb@MemoryOrder = "XYZ"
    tslb@description = "soil temperature"
    tslb@units = "K"
    tslb@stagger = "Z"
    tslb@coordinates = "XLONG XLAT"
lhsoi   = new((/ntimes, subgrid_type, grid_sz(0), grid_sz(1)/), "float")
    lhsoi@FieldType=104
    lhsoi@MemoryOrder = "XYZ"
    lhsoi@description = "LH from soil"
    lhsoi@units = "W/m^2"
    lhsoi@stagger = "Z"
    lhsoi@coordinates = "XLONG XLAT"
lhtran   = new((/ntimes, subgrid_type, grid_sz(0), grid_sz(1)/), "float")
    lhtran@FieldType=104
    lhtran@MemoryOrder = "XYZ"
    lhtran@description = "LH from transpiration"
    lhtran@units = "W/m^2"
    lhtran@stagger = "Z"
    lhtran@coordinates = "XLONG XLAT"
lhveg   = new((/ntimes, subgrid_type, grid_sz(0), grid_sz(1)/), "float")
    lhveg@FieldType=104
    lhveg@MemoryOrder = "XYZ"
    lhveg@description = "LH from vegetation"
    lhveg@units = "W/m^2"
    lhveg@stagger = "Z"
    lhveg@coordinates = "XLONG XLAT"
  smois  = new((/ntimes, soil_layers, grid_sz(0), grid_sz(1)/), "float")
    smois@FieldType=104
    smois@MemoryOrder = "XYZ"
    smois@description = "soil moisture"
    smois@units = "m3 m-3"
    smois@stagger = "Z"
    smois@coordinates = "XLONG XLAT"
    
;derived VAR 

 td_plev    = new((/ntimes, nlevs, grid_sz(0), grid_sz(1)/), "float")
    td_plev@FieldType=104
    td_plev@MemoryOrder = "XYZ"
    td_plev@description = " dew point temperature"
    td_plev@units = "C"
    td_plev@stagger = ""
    td_plev@coordinates = "XLONG XLAT"

td2    = new((/ntimes, grid_sz(0), grid_sz(1)/), "float")
    td2@FieldType=104
    td2@MemoryOrder = "XY "
    td2@description = "2m dew pt temperature"
    td2@units = "C"
    td2@stagger = ""
    td2@coordinates = "XLONG XLAT"

    
rh_plev = new((/ntimes, nlevs, grid_sz(0), grid_sz(1)/), "float")   
    rh_plev@FieldType=104
    rh_plev@MemoryOrder = "XYZ"
    rh_plev@description = "RH"
    rh_plev@units = "percent"
    rh_plev@stagger = ""
    rh_plev@coordinates = "XLONG XLAT"
    
rh2 = new((/ntimes, grid_sz(0), grid_sz(1)/), "float")
    rh2@FieldType=104
    rh2@MemoryOrder = "XY"
    rh2@description = "2m RH"
    rh2@units = "percent"
    rh2@stagger = ""
    rh2@coordinates = "XLONG XLAT"

pw = new((/ntimes, grid_sz(0), grid_sz(1)/), "float")
    pw@FieldType=104
    pw@MemoryOrder = "XY"
    pw@description = "precipitable water"
    pw@units = "mm"
    pw@stagger = ""
    pw@coordinates = "XLONG XLAT"

avo_plev    = new((/ntimes, nlevs, grid_sz(0), grid_sz(1)/), "float")
    avo_plev@FieldType=104
    avo_plev@MemoryOrder = "XYZ"
    avo_plev@description = " absolute vorticity "
    avo_plev@units = "10^-5s^-1"
    avo_plev@stagger = ""
    avo_plev@coordinates = "XLONG XLAT"

pvo_plev    = new((/ntimes, nlevs, grid_sz(0), grid_sz(1)/), "float")
    pvo_plev@FieldType=104
    pvo_plev@MemoryOrder = "XYZ"
    pvo_plev@description = " potential vorticity "
    pvo_plev@units = "PVU"
    pvo_plev@stagger = ""
    pvo_plev@coordinates = "XLONG XLAT"

theta_plev    = new((/ntimes, nlevs, grid_sz(0), grid_sz(1)/), "float")
    theta_plev@FieldType=104
    theta_plev@MemoryOrder = "XYZ"
    theta_plev@description = " potential temperature "
    theta_plev@units = "K"
    theta_plev@stagger = ""
    theta_plev@coordinates = "XLONG XLAT"

eq_theta_plev    = new((/ntimes, nlevs, grid_sz(0), grid_sz(1)/), "float")
    eq_theta_plev@FieldType=104
    eq_theta_plev@MemoryOrder = "XYZ"
    eq_theta_plev@description = " equivalent potential temperature "
    eq_theta_plev@units = "K"
    eq_theta_plev@stagger = ""
    eq_theta_plev@coordinates = "XLONG XLAT"

cape_2d = new((/ntimes, 4, grid_sz(0), grid_sz(1)/), "float")
    cape_2d@FieldType=104
    cape_2d@MemoryOrder = "XY"
    cape_2d@description = "mcape mcin lcl lfc"
    cape_2d@units = "diff units"
    cape_2d@stagger = ""
    cape_2d@coordinates = "XLONG XLAT"

cape_3d    = new((/ntimes, nlevs, grid_sz(0), grid_sz(1)/), "float")
    cape_3d@FieldType=104
    cape_3d@MemoryOrder = "XYZ"
    cape_3d@description = " 3D mcape "
    cape_3d@units = "J/kg?"
    cape_3d@stagger = ""
    cape_3d@coordinates = "XLONG XLAT"

cin_3d    = new((/ntimes, nlevs, grid_sz(0), grid_sz(1)/), "float")
    cin_3d@FieldType=104
    cin_3d@MemoryOrder = "XYZ"
    cin_3d@description = " 3D  mcin "
    cin_3d@units = "J/kg?"
    cin_3d@stagger = ""
    cin_3d@coordinates = "XLONG XLAT"

omega_plev    = new((/ntimes, nlevs, grid_sz(0), grid_sz(1)/), "float")
    omega_plev@FieldType=104
    omega_plev@MemoryOrder = "XYZ"
    omega_plev@description = " vertical velocity "
    omega_plev@units = "Pa/s?"
    omega_plev@stagger = ""
    omega_plev@coordinates = "XLONG XLAT"

ctt = new((/ntimes, grid_sz(0), grid_sz(1)/), "float")
    ctt@FieldType=104
    ctt@MemoryOrder = "XY"
    ctt@description = "cloud top temperature"
    ctt@units = "degC"
    ctt@stagger = ""
    ctt@coordinates = "XLONG XLAT"


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; define output netCDF file
;=====================================================================
   
   file_out = "WRF_daily_ideal_d0"+domain+"_"+year+"-"+mon+".nc"
   system("/bin/rm -f "+file_out)   ; remove any pre-existing file
   fout = addfile(file_out,"c")

;===================================================================
; explicitly declare file definition mode. Improve efficiency.
;===================================================================
   setfileoption(fout,"DefineMode",True)

;===================================================================
; create global attributes of the file
;===================================================================
   fAtt               = True            ; assign file attributes
   if(.not.all(ismissing(WRFatt_names))) then
     do i = 0,dimsizes(WRFatt_names)-1
       fAtt@$WRFatt_names(i)$ = b@$WRFatt_names(i)$
     end do
   end if
   fAtt@TITLE         = "UNL RCMF WRF daily archive"
   fAtt@CONVENTIONS   = "None"
   fAtt@CREATION_DATE = systemfunc ("date")
   fileattdef( fout, fAtt )            ; copy file attributes

;===================================================================
; predefine the coordinate variables and their dimensionality
; Note: to get an UNLIMITED record dimension, we set the dimensionality
; to -1 (or the actual size) and set the dimension name to True.
;===================================================================
   dimNames = (/"time", "pres_lev", "south_north", "west_east", "soil_layers", "cape3dvar", "cape2dvar","subgrid_type"/)
   dimSizes = (/ -1   ,  nlevs,      grid_sz(0),    grid_sz(1), soil_layers, 2, 4, 12/)
   dimUnlim = (/ True ,  False,      False,         False,      False,	False, False, False/)
   filedimdef(fout,dimNames,dimSizes,dimUnlim)

;===================================================================
; predefine the dimensionality of the variables to be written out
;===================================================================
   dimName3d = dimNames(0:3)
   dimName2d = (/"time", "south_north", "west_east"/)
   dimSoil   = (/"time","soil_layers","south_north","west_east"/)
   dimSubgr  = (/"time","subgrid_type","south_north","west_east"/)
   dimcape2d = (/"time", "cape2dvar", "south_north", "west_east"/)
   dimcape3d = (/"time", "cape3dvar", "pres_lev", "south_north", "west_east"/)
   filevardef(fout, "TIME", "integer", "time")
   filevardef(fout, "PRES_LEV", "float", "pres_lev")
   filevardef(fout, "DZS", "float", "soil_layers")
   filevardef(fout, "XLAT", "float", dimName2d)
   filevardef(fout, "XLONG", "float", dimName2d)

   filevardef(fout, "QIRRIG", "float", dimName2d)
   filevardef(fout, "WA_COLAVG", "float", dimName2d)
   filevardef(fout, "WT_COLAVG", "float", dimName2d)
   filevardef(fout, "ZWT_COLAVG", "float", dimName2d)
   filevardef(fout, "AREA_FRAC", "float", dimName2d)
   
   filevardef(fout, "LU_INDEX", "float", dimName2d)
   filevardef(fout, "LANDMASK", "float", dimName2d)
   filevardef(fout, "IVGTYP", "float", dimName2d)
   filevardef(fout, "ISLTYP", "float", dimName2d)
   filevardef(fout, "VEGFRA", "float", dimName2d)
   filevardef(fout, "LAI", "float", dimName2d)
   filevardef(fout, "HGT", "float", dimName2d)
   filevardef(fout, "CANWAT", "float", dimName2d)
   filevardef(fout, "CLDFRA", "float", dimName3d)
   filevardef(fout, "GLW", "float", dimName2d)
   filevardef(fout, "GRDFLX", "float", dimName2d)
   filevardef(fout, "LWUP", "float", dimName2d)
   filevardef(fout, "OLR", "float", dimName2d)
   filevardef(fout, "SH2O", "float", dimSoil)
   filevardef(fout, "SWDOWN", "float", dimName2d)
   filevardef(fout, "TH2", "float", dimName2d)
   filevardef(fout, "PSFC", "float", dimName2d)
   filevardef(fout, "PMSL", "float", dimName2d)
   filevardef(fout, "T2", "float", dimName2d)
   filevardef(fout, "TD2", "float", dimName2d)
   filevardef(fout, "RH2", "float", dimName2d)
   filevardef(fout, "PW", "float", dimName2d)
   filevardef(fout, "RH", "float", dimName3d)
   filevardef(fout, "T2_MIN", "float", dimName2d)
   filevardef(fout, "T2_MAX", "float", dimName2d)
   filevardef(fout, "Q2", "float", dimName2d)
   filevardef(fout, "LH", "float", dimName2d)
   filevardef(fout, "PBLH", "float", dimName2d)
   filevardef(fout, "HFX", "float", dimName2d)
   filevardef(fout, "QFX", "float", dimName2d)
   filevardef(fout, "U10", "float", dimName2d)
   filevardef(fout, "V10", "float", dimName2d)
  
   filevardef(fout, "RAINC", "float", dimName2d)
   filevardef(fout, "RAINNC", "float", dimName2d)
   filevardef(fout, "RAINSH", "float", dimName2d)
   filevardef(fout, "HAILNC", "float", dimName2d)
   filevardef(fout, "SFROFF", "float", dimName2d)
   filevardef(fout, "UDROFF", "float", dimName2d)
   filevardef(fout, "SABG", "float", dimName2d)
   filevardef(fout, "SABV", "float", dimName2d)
   filevardef(fout, "SHDMAX", "float", dimName2d)
   filevardef(fout, "SHDMIN", "float", dimName2d)
   filevardef(fout, "SNOWH", "float", dimName2d)
   filevardef(fout, "SEAICE", "float", dimName2d)
   filevardef(fout, "SNOWNC", "float", dimName2d)
  
   filevardef(fout, "PRCP", "float", dimName2d)
   filevardef(fout, "SNOW", "float", dimName2d)
   filevardef(fout, "SST", "float", dimName2d)
   filevardef(fout, "ALBEDO", "float", dimName2d)
   filevardef(fout, "ALBBCK", "float", dimName2d)
   filevardef(fout, "EMISS", "float", dimName2d)
   filevardef(fout, "XLAND", "float", dimName2d)
  
  ;3D  
   filevardef(fout, "PB", "float", dimName3d)
   filevardef(fout, "T", "float", dimName3d)
   filevardef(fout, "TD", "float", dimName3d)
   filevardef(fout, "Z", "float", dimName3d)
   filevardef(fout, "Q", "float", dimName3d)
   filevardef(fout, "QRAIN", "float", dimName3d)
   filevardef(fout, "QCLOUD", "float", dimName3d)
   filevardef(fout, "QICE", "float", dimName3d)
   filevardef(fout, "QSNOW", "float", dimName3d)    
   filevardef(fout, "U", "float", dimName3d)
   filevardef(fout, "V", "float", dimName3d)
   filevardef(fout, "W", "float", dimName3d)
   filevardef(fout, "TSLB", "float", dimSoil)
   filevardef(fout, "LHSOI", "float", dimSubgr)
   filevardef(fout, "LHVEG", "float", dimSubgr)
   filevardef(fout, "LHTRAN", "float", dimSubgr)
   filevardef(fout, "SMOIS", "float", dimSoil)
   
   filevardef(fout, "AVO", "float", dimName3d)
   filevardef(fout, "ETH", "float", dimName3d)
   filevardef(fout, "OMG", "float", dimName3d)
   filevardef(fout, "PVO", "float", dimName3d)
   filevardef(fout, "THETA", "float", dimName3d)
   filevardef(fout, "CTT", "float", dimName2d)
   filevardef(fout, "CAPE_2D", "float", dimcape2d)
   filevardef(fout, "CAPE_3D", "float", dimName3d)
   filevardef(fout, "CIN_3D", "float", dimName3d)

  ; filevardef(fout, "T", "float", dimName3d)
  ; filevardef(fout, "T2", "float", dimName2d)
  ; filevardef(fout, "PRCP", "float", dimName2d)
   
;===================================================================
; Copy attributes associated with each variable to the file
; All attributes associated with each variable will be copied.
;====================================================================
   filevarattdef(fout, "TIME", time)
   filevarattdef(fout, "PRES_LEV" , interp_levels)
   filevarattdef(fout, "DZS" , DZS)
   filevarattdef(fout, "XLAT" , XLAT)
   filevarattdef(fout, "XLONG" , XLONG)
   
   filevarattdef(fout, "QIRRIG", qirrig)
   filevarattdef(fout, "WA_COLAVG", wa_colavg)
   filevarattdef(fout, "WT_COLAVG", wt_colavg)

   filevarattdef(fout, "LU_INDEX" , LU_INDEX)
   filevarattdef(fout, "LANDMASK" , LANDMASK)
   filevarattdef(fout, "IVGTYP" , IVGTYP)
   filevarattdef(fout, "ISLTYP" , ISLTYP)
   filevarattdef(fout, "VEGFRA" , VEGFRA)
   filevarattdef(fout, "LAI" , LAI)
;  filevarattdef(fout, "Z0" , Z0)
   filevarattdef(fout, "HGT" , HGT)
   filevarattdef(fout, "CANWAT" , canwat)
   filevarattdef(fout, "GLW" , glw)
   filevarattdef(fout, "GRDFLX" , grdflx)
   filevarattdef(fout, "LWUP" , lwup)
   filevarattdef(fout, "OLR" , olr)
   filevarattdef(fout, "SH2O" , sh2o)
   filevarattdef(fout, "SWDOWN" , swdown)
   filevarattdef(fout, "TH2" , th2)
   filevarattdef(fout, "ALBEDO" , ALBEDO)
   filevarattdef(fout, "ALBBCK" , ALBBCK)
   filevarattdef(fout, "EMISS" , EMISS)
   filevarattdef(fout, "XLAND" , XLAND)
   filevarattdef(fout, "PSFC", psfc)
   filevarattdef(fout, "PMSL", pmsl)
   filevarattdef(fout, "T2", t2)
   filevarattdef(fout, "TD2", td2)
   filevarattdef(fout, "RH2", rh2)
   filevarattdef(fout, "PW", pw)
 ; filevarattdef(fout, "CAPE2D", cape_2d)
   filevarattdef(fout, "T2_MIN", t2_min)
   filevarattdef(fout, "T2_MAX", t2_max)
   filevarattdef(fout, "Q2", q2)
   filevarattdef(fout, "LH", lh)
   filevarattdef(fout, "PBLH", pblh)
   filevarattdef(fout, "HFX", hfx)
   filevarattdef(fout, "QFX", qfx)
   filevarattdef(fout, "U10", u10)
   filevarattdef(fout, "V10", v10)
   filevarattdef(fout, "RAINC", rainc)
   filevarattdef(fout, "RAINNC", rainnc)
   filevarattdef(fout, "RAINSH", rainsh)
   filevarattdef(fout, "SFROFF", sfroff)
   filevarattdef(fout, "UDROFF", udroff)
   filevarattdef(fout, "SABG", sabg) 
   filevarattdef(fout, "SABV", sabv)
   filevarattdef(fout, "SHDMAX", shdmax)
   filevarattdef(fout, "SHDMIN", shdmin)
   filevarattdef(fout, "SNOWH", snowh )
   filevarattdef(fout, "SEAICE", seaice)
   filevarattdef(fout, "SNOWNC", snownc)
   filevarattdef(fout, "HAILNC", hailnc)
   filevarattdef(fout, "PRCP", prcp)
   filevarattdef(fout, "SMOIS", smois)
   filevarattdef(fout, "SNOW", snow)
   filevarattdef(fout, "SST", sst)
  
  
;3D  
  filevarattdef(fout, "ZWT_COLAVG", zwt_colavg)
  filevarattdef(fout, "AREA_FRAC", area_frac)

  filevarattdef(fout, "CLDFRA" , cldfra_plev)
  ;filevarattdef(fout, "P", p1_plev)
  filevarattdef(fout, "PB", pb_plev)
  filevarattdef(fout, "T", t_plev)
  filevarattdef(fout, "TD", td_plev)
  ;filevarattdef(fout, "CAPE3D", cape3d_plev)
  filevarattdef(fout, "RH", rh_plev)
  filevarattdef(fout, "Z", z_plev)
  filevarattdef(fout, "Q", q_plev)
  filevarattdef(fout, "QRAIN", qrain_plev)
  filevarattdef(fout, "QCLOUD", qcloud_plev)
  filevarattdef(fout, "QICE", qice_plev)
  filevarattdef(fout, "QSNOW", qsnow_plev)
  filevarattdef(fout, "U", u_plev)
  filevarattdef(fout, "V", v_plev)
  filevarattdef(fout, "W", w_plev)
  filevarattdef(fout, "TSLB", tslb)
  filevarattdef(fout, "LHSOI", lhsoi)
  filevarattdef(fout, "LHVEG", lhveg)
  filevarattdef(fout, "LHTRAN", lhtran)

  filevarattdef(fout, "AVO", avo_plev)
  filevarattdef(fout, "ETH", eq_theta_plev)
  filevarattdef(fout, "CAPE_2D", cape_2d)
  filevarattdef(fout, "CAPE_3D", cape_3d)
  filevarattdef(fout, "CIN_3D", cin_3d)
  filevarattdef(fout, "OMG", omega_plev)
  filevarattdef(fout, "PVO", pvo_plev)
  filevarattdef(fout, "CTT", ctt)
  filevarattdef(fout, "THETA", theta_plev)
  
 ; filevarattdef(fout, "T", t_plev)
 ; filevarattdef(fout, "T2", t2)
 ; filevarattdef(fout, "PRCP", prcp)
;===================================================================
; explicitly exit file definition mode. **NOT REQUIRED**
;===================================================================
   setfileoption(fout,"DefineMode",False)

  fout->PRES_LEV   = (/interp_levels/)
  fout->DZS        = (/DZS/)

  do iday = 0,ndays-1
    a = addfile(files(iday),"r")   ; current day
    b = addfile(files(iday+1),"r") ; next day, needed to get daily precip

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Get date from first time in file
    wrf_times  = a->Times  ; get times in the file
    time = (/ wrf_times_c(wrf_times(0:0,:),3)/100 /)    ; convert to YYYYMMDD

    print("day: "+iday+" timestamp: "+time)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Get the 3D variables we need

    p = wrf_user_getvar(a,"p", -1)      ; pressure
    pb = wrf_user_getvar(a,"PB", -1)      ; pressure
    t = wrf_user_getvar(a,"tk", -1)     ; T in K
    td = wrf_user_getvar(a,"td", -1)     ; dew pt temperature
    rh = wrf_user_getvar(a,"rh", -1)     ; dew pt temperature
    z = wrf_user_getvar(a,"z", -1)      ; height
    q = wrf_user_getvar(a,"QVAPOR", -1) ; mixing ratio
    qrain = wrf_user_getvar(a,"QRAIN", -1) ; rain water mixing ratio
    qcloud = wrf_user_getvar(a,"QCLOUD", -1) ; cloud water mixing ratio
    qice = wrf_user_getvar(a,"QICE", -1) ; ice mixing ratio
    qsnow = wrf_user_getvar(a,"QSNOW", -1) ; snow water mixing ratio
    u = wrf_user_getvar(a,"ua", -1)     ; u averaged to mass points
    v = wrf_user_getvar(a,"va", -1)     ; v averaged to mass points
    w = wrf_user_getvar(a,"wa", -1)     ; v averaged to mass points
    cldfra = wrf_user_getvar(a,"CLDFRA", -1) ; Cloud fraction
    avo = wrf_user_getvar(a,"avo", -1)     ; avo averaged to mass points
    eth = wrf_user_getvar(a,"eth", -1)     ; eth averaged to mass points
    omg = wrf_user_getvar(a,"omg", -1)     ; omg averaged to mass points
    pvo = wrf_user_getvar(a,"pvo", -1)     ; pvo averaged to mass points
    theta = wrf_user_getvar(a,"theta", -1)     ; theta averaged to mass points
    cape_3d_xx = wrf_user_getvar(a,"cape_3d", -1)     ; cape 3d averaged to mass points
    cape_2d_xx = wrf_user_getvar(a,"cape_2d", -1)     ; cape 3d averaged to mass points


  ; interpolate to mandatory pressure levels
    opts=True
    opts@extrapolate=True
    t_plev(0,:,:,:) = dim_avg_n(wrf_user_vert_interp(a,t,"pres",interp_levels,opts), 0)
    td_plev(0,:,:,:) = dim_avg_n(wrf_user_vert_interp(a,td,"pres",interp_levels,opts), 0)
    rh_plev(0,:,:,:) = dim_avg_n(wrf_user_vert_interp(a,rh,"pres",interp_levels,opts), 0)
    z_plev(0,:,:,:) = dim_avg_n(wrf_user_vert_interp(a,z,"pres",interp_levels,opts), 0)
    pb_plev(0,:,:,:) = dim_avg_n(wrf_user_vert_interp(a,pb,"pres",interp_levels,opts), 0)
    q_plev(0,:,:,:) = dim_avg_n(wrf_user_vert_interp(a,q,"pres",interp_levels,opts), 0)
    qrain_plev(0,:,:,:) = dim_avg_n(wrf_user_vert_interp(a,qrain,"pres",interp_levels,opts), 0)
    qcloud_plev(0,:,:,:) = dim_avg_n(wrf_user_vert_interp(a,qcloud,"pres",interp_levels,opts), 0)
    qice_plev(0,:,:,:) = dim_avg_n(wrf_user_vert_interp(a,qice,"pres",interp_levels,opts), 0)
    qsnow_plev(0,:,:,:) = dim_avg_n(wrf_user_vert_interp(a,qsnow,"pres",interp_levels,opts), 0)
    cldfra_plev(0,:,:,:) = dim_avg_n(wrf_user_vert_interp(a,cldfra,"pres",interp_levels,opts), 0)
    u_plev(0,:,:,:) = dim_avg_n(wrf_user_vert_interp(a,u,"pres",interp_levels,opts), 0)
    v_plev(0,:,:,:) = dim_avg_n(wrf_user_vert_interp(a,v,"pres",interp_levels,opts), 0)
    w_plev(0,:,:,:) = dim_avg_n(wrf_user_vert_interp(a,w,"pres",interp_levels,opts), 0)

    avo_plev(0,:,:,:) = dim_avg_n(wrf_user_vert_interp(a,avo,"pres",interp_levels,opts), 0)
    pvo_plev(0,:,:,:) = dim_avg_n(wrf_user_vert_interp(a,pvo,"pres",interp_levels,opts), 0)
    theta_plev(0,:,:,:) = dim_avg_n(wrf_user_vert_interp(a,theta,"pres",interp_levels,opts), 0)
    eq_theta_plev(0,:,:,:) = dim_avg_n(wrf_user_vert_interp(a,eth,"pres",interp_levels,opts), 0)
    omega_plev(0,:,:,:) = dim_avg_n(wrf_user_vert_interp(a,omg,"pres",interp_levels,opts), 0)

    cape_xx=cape_3d_xx(0,:,:,:,:)
    cin_xx=cape_3d_xx(0,:,:,:,:)
    cape_3d(0,:,:,:) = dim_avg_n(wrf_user_vert_interp(a,cape_xx,"pres",interp_levels,opts), 0)
    cin_3d(0,:,:,:) = dim_avg_n(wrf_user_vert_interp(a,cin_xx,"pres",interp_levels,opts), 0)
    print(dimsizes(cape_3d))
    print(dimsizes(cin_3d))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; get 2D variables we need
  
    cape_2d(0,:,:,:) = dim_avg_n(wrf_user_getvar(a,"cape_2d",-1), 1)
  ; 2m temperature (C)
  ; t2(0,:,:) = dim_avg_n(wrf_user_getvar(a,"T2", -1), 0)

    psfc(0,:,:) = dim_avg_n(wrf_user_getvar(a,"PSFC", -1), 0) ; surface pressure
    psfc = psfc *0.01                                         ; convert to hPa
    pmsl(0,:,:) = dim_avg_n(wrf_user_getvar(a,"slp", -1), 0)  ; mean sea-level pressure
    t2(0,:,:) = dim_avg_n(wrf_user_getvar(a,"T2", -1), 0)     ; 2m temperature
    
    td2(0,:,:) = dim_avg_n(wrf_user_getvar(a,"td2", -1), 0)     ; 2m dew pt temperature
    rh2(0,:,:) = dim_avg_n(wrf_user_getvar(a,"rh2", -1), 0)     ; 2m RH 
    pw(0,:,:) = dim_avg_n(wrf_user_getvar(a,"pw", -1), 0)     ; precipitable water
    t2_min(0,:,:) = dim_min_n(wrf_user_getvar(a,"T2", -1), 0)
    t2_max(0,:,:) = dim_max_n(wrf_user_getvar(a,"T2", -1), 0)
    q2(0,:,:) = dim_avg_n(wrf_user_getvar(a,"Q2", -1), 0)     ; 2m specific humidity
    qfx(0,:,:) = dim_avg_n(wrf_user_getvar(a,"QFX", -1), 0)   ; upward moisture flux at the sutface
    lh(0,:,:) = dim_avg_n(wrf_user_getvar(a,"LH", -1), 0)     ; latent heat flux at the sutface
    pblh(0,:,:) = dim_avg_n(wrf_user_getvar(a,"PBLH", -1), 0) ; pbl height
    hfx(0,:,:) = dim_avg_n(wrf_user_getvar(a,"HFX", -1), 0)   ; sensible heat flux at the sutface
    u10(0,:,:) = dim_avg_n(wrf_user_getvar(a,"U10", -1), 0)   ; 10m U-component
    v10(0,:,:) = dim_avg_n(wrf_user_getvar(a,"V10", -1), 0)   ; 10m V-component
    
  
    canwat(0,:,:) = dim_avg_n(wrf_user_getvar(a,"CANWAT", -1), 0)   ; canopy water
    glw(0,:,:) = dim_avg_n(wrf_user_getvar(a,"GLW", -1), 0)   ;
    grdflx(0,:,:) = dim_avg_n(wrf_user_getvar(a,"GRDFLX", -1), 0)   ;
    lwup(0,:,:) = dim_avg_n(wrf_user_getvar(a,"LWUP", -1), 0)   ;
    olr(0,:,:) = dim_avg_n(wrf_user_getvar(a,"OLR", -1), 0)   ;
    swdown(0,:,:) = dim_avg_n(wrf_user_getvar(a,"SWDOWN", -1), 0)   ;
    th2(0,:,:) = dim_avg_n(wrf_user_getvar(a,"TH2", -1), 0)   ;
  ; rainc(0,:,:) = dim_avg_n(wrf_user_getvar(a,"RAINC", -1), 0)   ; 
  ; rainnc(0,:,:) = dim_avg_n(wrf_user_getvar(a,"RAINNC", -1), 0)   ; 
  ; rainsh(0,:,:) = dim_avg_n(wrf_user_getvar(a,"RAINSH", -1), 0)   ; 
    sfroff(0,:,:) = dim_avg_n(wrf_user_getvar(a,"SFROFF", -1), 0)   ; 
    udroff(0,:,:) = dim_avg_n(wrf_user_getvar(a,"UDROFF", -1), 0)   ;
    sabg(0,:,:) = dim_avg_n(wrf_user_getvar(a,"SABG", -1), 0)   ; 
    sabv(0,:,:) = dim_avg_n(wrf_user_getvar(a,"SABV", -1), 0)   ; 
    shdmax(0,:,:) = dim_avg_n(wrf_user_getvar(a,"SHDMAX", -1), 0)   ; 
    shdmin(0,:,:) = dim_avg_n(wrf_user_getvar(a,"SHDMIN", -1), 0)   ; 
    snowh(0,:,:) = dim_avg_n(wrf_user_getvar(a,"SNOWH", -1), 0)   ; 
    seaice(0,:,:) = dim_avg_n(wrf_user_getvar(a,"SEAICE", -1), 0)     ;
  ; snownc(0,:,:) = dim_avg_n(wrf_user_getvar(a,"SNOWNC", -1), 0)     ;

    wa_colavg(0,:,:) = dim_avg_n(wrf_user_getvar(a,"WA_COLAVG", -1), 0);
    wt_colavg(0,:,:) = dim_avg_n(wrf_user_getvar(a,"WT_COLAVG", -1), 0);
    zwt_colavg(0,:,:) = dim_avg_n(wrf_user_getvar(a,"ZWT_COLAVG", -1), 0);

  ; daily precip is difference between succesive 00Z accumulations
    prcp(0,:,:) = (b->RAINC(0,:,:)+b->RAINNC(0,:,:)) \
                - (a->RAINC(0,:,:)+a->RAINNC(0,:,:))
                  

    rainc(0,:,:) = (b->RAINC(0,:,:))-(a->RAINC(0,:,:))
    rainnc(0,:,:) = (b->RAINNC(0,:,:))-(a->RAINNC(0,:,:))
    rainsh(0,:,:) = (b->RAINSH(0,:,:))-(a->RAINSH(0,:,:))
    snownc(0,:,:) = (b->SNOWNC(0,:,:))-(a->SNOWNC(0,:,:))
    hailnc(0,:,:) = (b->HAILNC(0,:,:))-(a->HAILNC(0,:,:))
    qirrig(0,:,:) = (b->QIRRIG(0,:,:))-(a->QIRRIG(0,:,:))


    tslb(0,:,:,:) = dim_avg_n(wrf_user_getvar(a,"TSLB", -1), 0)   ; soil layer temperature
    lhsoi(0,:,:,:) = dim_avg_n(wrf_user_getvar(a,"LHSOI", -1), 0)   ; LH from soil
    lhveg(0,:,:,:) = dim_avg_n(wrf_user_getvar(a,"LHVEG", -1), 0)   ; LH from vegetation
    lhtran(0,:,:,:) = dim_avg_n(wrf_user_getvar(a,"LHTRAN", -1), 0)   ; LH from transpiration
    smois(0,:,:,:) = dim_avg_n(wrf_user_getvar(a,"SMOIS", -1), 0) ; soil layer volumatric moisture
    sh2o(0,:,:,:)   = dim_avg_n(wrf_user_getvar(a,"SH2O", -1), 0) ; soil liquid water
    snow(0,:,:) = dim_avg_n(wrf_user_getvar(a,"SNOW", -1), 0)     ; snow water equivalent
    sst(0,:,:) = dim_avg_n(wrf_user_getvar(a,"SST", -1), 0)     ; sea surface temperature
    ctt(0,:,:) = dim_avg_n(wrf_user_getvar(a,"ctt", -1), 0)     ; cloud top temperature

    area_frac(0,:,:) = a->AREA_FRAC(0,:,:)
    XLAT(0,:,:)     = a->XLAT(0,:,:)
    XLONG(0,:,:)    = a->XLONG(0,:,:)
    LU_INDEX(0,:,:) = a->LU_INDEX(0,:,:)
    LANDMASK(0,:,:) = a->LANDMASK(0,:,:)
    IVGTYP(0,:,:)   = a->IVGTYP(0,:,:)
    ISLTYP(0,:,:)   = a->ISLTYP(0,:,:)
    VEGFRA(0,:,:)   = a->VEGFRA(0,:,:)
    LAI(0,:,:)      = a->LAI(0,:,:)
;    Z0(0,:,:)       = a->Z0(0,:,:)
    HGT(0,:,:)      = a->HGT(0,:,:)
    ALBEDO(0,:,:)   = a->ALBEDO(0,:,:)
    ALBBCK(0,:,:)   = a->ALBBCK(0,:,:)
    EMISS(0,:,:)    = a->EMISS(0,:,:)
    XLAND(0,:,:)    = a->XLAND(0,:,:)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; write time varying data to the netCDF file
    ; fout->TIME(iday)            = (/time/)
    ; fout->XLAT(iday,:,:)        = (/XLAT/)
    ; fout->XLONG(iday,:,:)       = (/XLONG/)
    ; fout->T(iday,:,:,:)         = (/t_plev/)
    ; fout->T2(iday,:,:)          = (/t2/)
    ; fout->PRCP(iday,:,:)        = (/prcp/)

    fout->TIME(iday)            = (/time/)
    fout->T(iday,:,:,:)         = (/t_plev/)
    fout->TD(iday,:,:,:)         = (/td_plev/)
    fout->RH(iday,:,:,:)         = (/rh_plev/)
    ;fout->CAPE3D(iday,:,:,:)         = (/cape3d_plev/)
   ; fout->CAPE2D(iday,:,:)         = (/cape2d/)
    fout->Z(iday,:,:,:)         = (/z_plev/)
    fout->Q(iday,:,:,:)         = (/q_plev/)
    fout->PB(iday,:,:,:)         = (/pb_plev/)
   ; fout->PH(iday,:,:,:)         = (/phb_plev/)
  ;  fout->PHB(iday,:,:,:)         = (/phb_plev/)
    fout->QRAIN(iday,:,:,:)     = (/qrain_plev/)
    fout->QCLOUD(iday,:,:,:)    = (/qcloud_plev/)
    fout->QICE(iday,:,:,:)      = (/qice_plev/)
    fout->QSNOW(iday,:,:,:)      = (/qsnow_plev/)
    fout->U(iday,:,:,:)         = (/u_plev/)
    fout->V(iday,:,:,:)         = (/v_plev/)
    fout->W(iday,:,:,:)         = (/w_plev/)
    fout->CLDFRA(iday,:,:,:)    = (/cldfra_plev/)
    fout->SMOIS(iday,:,:,:)     = (/smois/)
    fout->SH2O(iday,:,:,:)     = (/sh2o/)
    fout->TSLB(iday,:,:,:)      = (/tslb/)
    fout->LHSOI(iday,:,:,:)      = (/lhsoi/)
    fout->LHVEG(iday,:,:,:)      = (/lhveg/)
    fout->LHTRAN(iday,:,:,:)      = (/lhtran/)

    fout->CAPE_3D(iday,:,:,:)         = (/cape_3d/)
    fout->CIN_3D(iday,:,:,:)         = (/cin_3d/)
    fout->CAPE_2D(iday,:,:,:)         = (/cape_2d/)
    fout->AVO(iday,:,:,:)         = (/avo_plev/)
    fout->PVO(iday,:,:,:)         = (/pvo_plev/)
    fout->ETH(iday,:,:,:)         = (/eq_theta_plev/)
    fout->OMG(iday,:,:,:)         = (/omega_plev/)
    fout->THETA(iday,:,:,:)         = (/theta_plev/)


;2D 
    fout->CTT(iday,:,:)        = (/ctt/)

    fout->PSFC(iday,:,:)        = (/psfc/)
    fout->PMSL(iday,:,:)        = (/pmsl/)
    fout->T2(iday,:,:)          = (/t2/)
    fout->TD2(iday,:,:)          = (/td2/)
    fout->RH2(iday,:,:)          = (/rh2/)
    fout->PW(iday,:,:)          = (/pw/)
    ;fout->CAPE2D(iday,:,:)          = (/cape_2d/)
    fout->T2_MIN(iday,:,:)      = (/t2_min/)
    fout->T2_MAX(iday,:,:)      = (/t2_max/)
    fout->Q2(iday,:,:)          = (/q2/)
    fout->CANWAT(iday,:,:)          = (/canwat/) 
    fout->GLW(iday,:,:)          = (/glw/)
    fout->GRDFLX(iday,:,:)          = (/grdflx/)
    fout->LWUP(iday,:,:)          = (/lwup/)
    fout->OLR(iday,:,:)          = (/olr/)
    fout->SWDOWN(iday,:,:)          = (/swdown/)
    fout->TH2(iday,:,:)          = (/th2/)
    fout->LH(iday,:,:)          = (/lh/)
    fout->PBLH(iday,:,:)          = (/pblh/)
    fout->HFX(iday,:,:)          = (/hfx/)
    fout->QFX(iday,:,:)          = (/qfx/)
    fout->U10(iday,:,:)         = (/u10/)
    fout->V10(iday,:,:)         = (/v10/)
    fout->PRCP(iday,:,:)        = (/prcp/)
    fout->RAINC(iday,:,:)        = (/rainc/)
    fout->RAINNC(iday,:,:)        = (/rainnc/)
    fout->RAINSH(iday,:,:)        = (/rainsh/)
    fout->SFROFF(iday,:,:)        = (/sfroff/)
    fout->UDROFF(iday,:,:)        = (/udroff/)
    fout->SABG(iday,:,:)        = (/sabg/)
    fout->SABV(iday,:,:)        = (/sabv/)
    fout->SHDMAX(iday,:,:)        = (/shdmax/)
    fout->SHDMIN(iday,:,:)        = (/shdmin/)
    fout->SNOWH(iday,:,:)        = (/snowh/)
    fout->SEAICE(iday,:,:)        = (/seaice/)
    fout->SNOWNC(iday,:,:)        = (/snownc/)
    fout->HAILNC(iday,:,:)        = (/hailnc/)
    fout->SNOW(iday,:,:)        = (/snow/)
    fout->SST(iday,:,:)         = (/sst/)
    fout->XLAT(iday,:,:)        = (/XLAT/)
    fout->XLONG(iday,:,:)       = (/XLONG/)
    fout->LU_INDEX(iday,:,:)    = (/LU_INDEX/)
    fout->LANDMASK(iday,:,:)    = (/LANDMASK/)
    fout->IVGTYP(iday,:,:)      = (/IVGTYP/)
    fout->ISLTYP(iday,:,:)      = (/ISLTYP/)
    fout->VEGFRA(iday,:,:)      = (/VEGFRA/)
    fout->LAI(iday,:,:)         = (/LAI/)
    fout->HGT(iday,:,:)         = (/HGT/)
    fout->ALBEDO(iday,:,:)      = (/ALBEDO/)
    fout->ALBBCK(iday,:,:)      = (/ALBBCK/)
    fout->EMISS(iday,:,:)       = (/EMISS/)
    fout->XLAND(iday,:,:)       = (/XLAND/)

    fout->QIRRIG(iday,:,:)    = (/qirrig/)
    fout->WA_COLAVG(iday,:,:) = (/wa_colavg/)
    fout->WT_COLAVG(iday,:,:) = (/wt_colavg/)
    fout->ZWT_COLAVG(iday,:,:) = (/zwt_colavg/)
    fout->AREA_FRAC(iday,:,:) = (/area_frac/)

  end do                                             ; end of day loop

end
