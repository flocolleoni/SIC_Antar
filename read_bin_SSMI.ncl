;NCL script that converts daily Sea Ice Concentrations from Nimbus-7 SMMR and DMSP SSM/I Passive Microwave Data binary data to netCDF format
;Data description http://nsidc.org/data/docs/daac/nsidc0051_gsfc_seaice.gd.html
;Data location ftp://sidads.colorado.edu/pub/DATASETS/seaice/polar-stereo/nasateam/final-gsfc/

;Created by Kolya Koldunov koldunovn@gmail.com, IMPRS-ESM, http://kodunov.net
;Based on script by Maria (Masha) Tsukernik, NCAR

load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"

;name for lat nad lon files
latfilename = "pss25lats_v3.dat"
lonfilename = "pss25lons_v3.dat"

nx = 316
ny = 332
ntimes=1
yyyy = 2016

;open lat lon files
; setfileoption("bin","ReadByteOrder","Native")

 recl=nx*ny

lat_raw = cbinread(latfilename,-1,"integer")
lon_raw = cbinread(lonfilename,-1,"integer")

lat = lat_raw/100000.
lon = lon_raw/100000.



lat2d = onedtond(lat,(/ny,nx/))
lon2d = onedtond(lon,(/ny,nx/))

;print(lat2d)

lat2d@units = "degree_north"
lon2d@units = "degree_east"

lat2d@long_name = "latitude"
lat2d@lstandard_name = "grid_latitude"

lon2d@long_name = "longitude"
lon2d@standard_name = "grid_longitude" ;


;----------------------------------------------------
; INPUT file
;----------------------------------------------------
fili= filin  ;systemfunc("ls nt_"+yyyy+month+"*.bin")
print(fili)

ice3d = new((/ntimes,ny,nx/),typeof(lat2d))


 fcoord = addfile("xy_cart_nimbus7.nc","r")
 x = fcoord->xgrid
 y = fcoord->ygrid
 
; define new coordinate vectors
;--------------------------------
;y = fspan(-90,-39.23,ny)
;x = fspan(0,360,nx)
time = new((/ntimes/),"double")


;print(x)

time@units = "months since "+yyyy+"-01-01"
;x@units =  "degrees_north"
;y@units =  "degrees_east"

;y=y(331:0:1)
;x=x(315:0:1)

;  x=ispan(1,316,1)
;  y=ispan(1,332,1)
x!0 = "x"
y!0 = "y"
time!0 = "time"

x&x        = x
y&y        = y
time&time  = time

lat2d!1 = "x"
lat2d!0 = "y"

lon2d!1 = "x"
lon2d!0 = "y"

lat2d&x = x
lat2d&y = y

lon2d&x = x
lon2d&y = y


do j=0,ntimes-1
;==============================  
 everyfil=fili

 setfileoption("bin","ReadByteOrder","Native")

 ;open the data file to inn variable
 inn =cbinread(everyfil,-1,"byte")

;convert our data from byte to float and drop first 300 records (header not needed)

 iceraw = byte2flt(inn(300:))
 ;ice_raw=iceraw

  ice_raw=new(recl,"float")
 printVarSummary(iceraw)
; print(iceraw)

 do i=0,recl-1
  if(iceraw(i).lt.0.) then
    ice_raw(i) = 255+iceraw(i)
  else
    ice_raw(i) = iceraw(i)
  end if
 end do

 ;Values have been scaled by 250
 ice_raw= ice_raw/250.

;in out data set we have several values that are not the data
;251/250 = 1.004    Circular mask used in the Arctic to cover the irregularly-shaped data gap around the pole (caused by the orbit inclination and instrument swath)
;252            Unused
;253/250 = 1.012    Coastlines
;254/250 = 1.016    Superimposed land mask
;255/250 = 1.02     Missing data

ice_raw04 = ice_raw
ice_raw04@_FillValue = 1.004
ice_raw12 = ice_raw
ice_raw12@_FillValue = 1.012
ice_raw16 = ice_raw
ice_raw16@_FillValue = 1.016
ice_raw02 = ice_raw
ice_raw02@_FillValue = 1.02


; here is a strange part
; we summ up all variables to "collect" _FillValue from 4 different variables. As result we have a variable with one _FillValue for everything that is not tsea ice concentration. Then we divide it to return to original values.  
ice_raw_sum = ice_raw12+ice_raw16+ice_raw04+ice_raw02
ice_fill = ice_raw_sum/4.

;reshape our 1D arrays to 2D arrays
ice2d = onedtond(ice_fill,(/ny,nx/))

printVarSummary(ice_fill)

;set up atributes for lat and lon files, and then make this files atributes of our data (ice2d). This is done to be able to plot data on curveliniat coordinates. If you plan laiter to put data to netCDF, you better remove this attributes from ice2d.
ice2d@lat2d = lat2d
ice2d@lon2d = lon2d


ice3d(j,:,:) = ice2d*100.

end do

;icetmp = where(ice3d.lt.0,0,ice3d)
;ice3d = icetmp

ice3d!0 = "time"
ice3d!1 = "y"
ice3d!2 = "x"

ice3d&time = time
ice3d&y    = y
ice3d&x    = x

ice3d@long_name = "sea_ice_concentration"
ice3d@units     = "frac."
ice3d@missinf_value = ice3d@_FillValue
 

;delete_VarAtts(ice2d,(/"lon2d","lat2d"/))

  system("/bin/rm -f tmp.nc");nt_"+yyyy+"0"+month+"_v1.1_s.nc")    ; remove if exists
  fout  = addfile ("tmp.nc","c");"nt_"+yyyy+"0"+month+"_v1.1_s.nc", "c")  ; open output file



;setfileoption(fout,"DefineMode",True)

fAtt               = True            ; assign file attributes
fAtt@title         = "Sea Ice Concentrations from Nimbus-7 SMMR and DMSP SSM/I Passive Microwave Data"  
fAtt@source_file   = "bynary files from ftp://sidads.colorado.edu/pub/DATASETS/seaice/polar-stereo/nasateam/final-gsfc/"
fAtt@Conventions   = "None"  
fAtt@creation_date = systemfunc ("date")        
fileattdef( fout, fAtt )            ; copy file attributes    

dimNames = (/"time", "y", "x"/)  
dimSizes = (/ -1   ,  ny,  nx /)
dimUnlim = (/ True , False, False/)  
filedimdef(fout,dimNames,dimSizes,dimUnlim)

;filevardef(fout, "time" ,typeof(time),getvardims(time))
;filevardef(fout, "x"  ,typeof(x),getvardims(x) )                          
;filevardef(fout, "y"  ,typeof(y),getvardims(y))                          
;filevardef(fout, "lon2d"  ,typeof(lon2d),getvardims(lon2d))                          
;filevardef(fout, "lat2d"    ,typeof(lat2d)  ,getvardims(lat2d))    
;filevardef(fout, "ICE"   ,typeof(ice3d) ,getvardims(ice3d))          


;filevarattdef(fout,"time" ,time)                    ; copy time attributes
;filevarattdef(fout,"x"  ,x)                     ; copy lev attributes
;filevarattdef(fout,"y"  ,y)                     ; copy lat attributes
;filevarattdef(fout,"lon2d"  ,lon2d)                     ; copy lon attributes
;filevarattdef(fout,"lat2d"   ,lat2d)                      ; copy PS attributes
;filevarattdef(fout,"ICE",ice3d)                     ; copy TOPOG attributes

setfileoption(fout,"DefineMode",False)
;
fout->time    = time
fout->x       = x
fout->y       = y
fout->lon2d    = lon2d
fout->lat2d    = lat2d
fout->ICE      = ice3d
