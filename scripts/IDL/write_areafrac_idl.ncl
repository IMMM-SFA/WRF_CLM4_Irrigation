;---------- originally created by Ben Yang for use with WRF-Noah ----------------
;---------- modified by Anjana in Aug 2018 to use with IDL codes of WRF-CLM4
; Script writes irrigation input data into wrfinput_d01 file
;--------------------------------------------------------------------------------

load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"

begin

year_str=getenv("year")
system("cp wrfinput_d01 wrfinput_d01_orig")

f=addfile("irrigation_input_areafrac_"+year_str+".nc","r")
irr0=f->AREA_FRAC
lat=f->lat
lon=f->long
ny0=dimsizes(lat)
nx0=dimsizes(lon)

irr1=new((/ny0,nx0+nx0/2/),float)
lon1=new(nx0+nx0/2,double)

irr1(:,0:nx0-1)=irr0*100
irr1(:,nx0:)=irr0(:,0:nx0/2-1)*100

lat1=lat
lon1(0:nx0-1)=lon
lon1(nx0:)=lon(0:nx0/2-1)+360

fi=addfile("wrfinput_d01.nc","r")
irr=fi->AREA_FRAC
lat2d=fi->XLAT(0,:,:)
lon2d=fi->XLONG(0,:,:)

dims=dimsizes(lat2d)
ny=dims(0)
nx=dims(1)

if(any(lon2d(:,nx-1) .lt. lon2d(ny/2,0)))then
  if(any(lon2d(:,nx-1) .gt. 0))then
    print("intepolation cannot be done")
    exit
  end if
  lon2d=where(lon2d.lt.0,lon2d+360,lon2d)
end if

ilat=ind( lat1 .ge. min(lat2d)-1 .and. lat1 .le. max(lat2d)+1 )
ilon=ind( lon1 .ge. min(lon2d)-1 .and. lon1 .le. max(lon2d)+1 )

irr  = (/rgrid2rcm (lat1(ilat), lon1(ilon), irr1(ilat,ilon), lat2d, lon2d, 0)/)

irr=where(ismissing(irr),0,irr)
delete(irr@_FillValue)

system("rm area2wrf.nc")
fout=addfile("area2wrf.nc","c")
fout->AREA_FRAC=irr

system("ncks -A -v AREA_FRAC area2wrf.nc wrfinput_d01")

end

