;---------- originally created by Ben Yang for use with WRF-Noah ----------------
;---------- modified by Anjana in Aug 2018 to use with IRR/IDL codes of WRF-CLM4
; Script writes irrigation input data into wrfinput_d01 file
;--------------------------------------------------------------------------------

load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"

begin

year_str=getenv("year")
system("cp wrfinput_d01 wrfinput_d01_step1")

f=addfile("irrigation_input_"+year_str+".nc","r")
irr0=f->IRRIG_WATERUSE
irr_paddy0=f->IRRIG_WATERUSE_PADDY
fgrd0=f->F_GRD
fsurf0=f->F_SURF
lat=f->lat
lon=f->long
ny0=dimsizes(lat)
nx0=dimsizes(lon)

irr1=new((/ny0,nx0+nx0/2/),float)
irr_paddy1=new((/ny0,nx0+nx0/2/),float)
fgrd1=new((/ny0,nx0+nx0/2/),float)
fsurf1=new((/ny0,nx0+nx0/2/),float)
lon1=new(nx0+nx0/2,double)

irr1(:,0:nx0-1)=irr0
irr1(:,nx0:)=irr0(:,0:nx0/2-1)
irr_paddy1(:,0:nx0-1)=irr_paddy0
irr_paddy1(:,nx0:)=irr_paddy0(:,0:nx0/2-1)
fgrd1(:,0:nx0-1)=fgrd0
fgrd1(:,nx0:)=fgrd0(:,0:nx0/2-1)
fsurf1(:,0:nx0-1)=fsurf0
fsurf1(:,nx0:)=fsurf0(:,0:nx0/2-1)

lat1=lat
lon1(0:nx0-1)=lon
lon1(nx0:)=lon(0:nx0/2-1)+360

fi=addfile("wrfinput_d01.nc","r")
irr=fi->IRRIG_WATERUSE
irr_paddy=fi->IRRIG_WATERUSE_PADDY
fgrd=fi->F_GRD
fsurf=fi->F_SURF
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

ilat=ind( lat1 .ge. min(lat2d)-1 .and. lat1 .le. max(lat2d)+1 )
ilon=ind( lon1 .ge. min(lon2d)-1 .and. lon1 .le. max(lon2d)+1 )

irr  = (/rgrid2rcm (lat1(ilat), lon1(ilon), irr1(ilat,ilon), lat2d, lon2d, 0)/)
irr_paddy  = (/rgrid2rcm (lat1(ilat), lon1(ilon), irr_paddy1(ilat,ilon), lat2d, lon2d, 0)/)
fgrd = (/rgrid2rcm (lat1(ilat), lon1(ilon), fgrd1(ilat,ilon), lat2d, lon2d, 0)/)
fsurf = (/rgrid2rcm (lat1(ilat), lon1(ilon), fsurf1(ilat,ilon), lat2d, lon2d, 0)/)

irr=where(ismissing(irr),0,irr)
delete(irr@_FillValue)
irr_paddy=where(ismissing(irr_paddy),0,irr_paddy)
delete(irr_paddy@_FillValue)
fgrd=where(ismissing(fgrd),0,fgrd)
delete(fgrd@_FillValue)
fsurf=where(ismissing(fsurf),0,fsurf)
delete(fsurf@_FillValue)

system("rm input2wrf.nc")
fout=addfile("input2wrf.nc","c")
fout->IRRIG_WATERUSE=irr
fout->IRRIG_WATERUSE_PADDY=irr_paddy
fout->F_GRD=fgrd
fout->F_SURF=fsurf

system("ncks -A -v IRRIG_WATERUSE,IRRIG_WATERUSE_PADDY,F_GRD,F_SURF input2wrf.nc wrfinput_d01")

end
    
