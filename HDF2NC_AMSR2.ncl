;-------------------------------------------------
; NOTE POUR MOI MEME
;
; reprojetter les donnees en lon-lat pour avoir des
; cartes plus precises
;
; Faire une boucle qui compte les jours sans glace
; pour faire une carte qui individualise le nombre de jour d'ouverture
; pour la saison d'ete
; Essayer de superposer la bathymetrie et les lignes sismiques ou bien
; Ou bien les zones de campagne
; 
; Pour chaque site, faire une courbe de l'evolution
; du SIC pour voir les jour d'ouverture potentiels
;

;*******************************************
; lcnative_1.ncl
;*******************************************
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"  
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"  
begin
;*******************************************
; open file and read in data
;*******************************************
  mydir2  = "/Users/Flo/Recherche/Projects/Antarctica_2017/SIC/AMSR2_Ross_Sea/"

  day ="23"
  month="01"
  year="2018"


  in1    = addfile (mydir2+"asi-AMSR2-s3125-"+year+month+day+"-v5.hdf", "r")
  sic1 = in1->ASI_Ice_Concentration  ; 348 at Dec 14th   336 Dec 1st


  in2   = addfile (mydir2+"LongitudeLatitudeGrid-s3125-RossSea.hdf", "r")
  lat2d = in2->Latitudes
  lon2d = in2->Longitudes    

  time = new((/1/),"double")   
  time@units = "days since "+year+"-"+month+"-"+day  
  time = 1 
 
  nx=800
  ny=800  
  x=ispan(800,1,1)
  y=ispan(1,800,1)

  x!0 = "x"
  y!0 = "y"
  time!0 = "time"  

  x&x = x
  y&y = y
  time&time  = time

  x@units =  "-"
  y@units =  "-" 

  lat2d!1 = "x"
  lat2d!0 = "y"

  lon2d!1 = "x"
  lon2d!0 = "y"

  lat2d&x = x
  lat2d&y = y

  lon2d&x = x
  lon2d&y = y

  lat2d@units =  "degrees_north"
  lon2d@units =  "degrees_east"
  
  lon2d=lonFlip(lon2d)

  sic = new((/1,ny,nx/),"double")   

  sic(0,:,:) = sic1

;  sic@_FillValue = -9999

  sic!0 = "time"
  sic!1 = "y"
  sic!2 = "x"

  sic&time    = time
  sic&y    = y
  sic&x    = x

  sic@long_name = "sea_ice_concentration"
  sic@units     = "frac."
  sic@missinf_value = sic@_FillValue
 

  sicfile="asi-AMSR2-s3125-"+year+month+day+"-v5.nc"
  system("/bin/rm -f " + sicfile);nt_"+yyyy+"0"+month+"_v1.1_s.nc")    ; remove if exists
  fout  = addfile (sicfile,"c")  ; open output file



setfileoption(fout,"DefineMode",True)

fAtt               = True            ; assign file attributes
fAtt@title         = "Sea Ice Concentrations from AMSRE-2"  
fAtt@source_file   = "HDF files from http://www.iup.uni-bremen.de:8084/amsr2data/asi_daygrid_swath/s3125/2016/dec/_RossSea/"
fAtt@Conventions   = "None"  
fAtt@creation_date = systemfunc ("date")        
fileattdef( fout, fAtt )            ; copy file attributes    

dimNames = (/"time","y", "x"/)  
dimSizes = (/-1,  ny,  nx /)
dimUnlim = (/True, False, False/)  
filedimdef(fout,dimNames,dimSizes,dimUnlim)

filevardef(fout, "time"   ,typeof(time)   ,getvardims(time))
filevardef(fout, "x"      ,typeof(x)      ,getvardims(x))                          
filevardef(fout, "y"      ,typeof(y)      ,getvardims(y))                          
filevardef(fout, "lon2d"  ,typeof(lon2d)  ,getvardims(lon2d))                          
filevardef(fout, "lat2d"  ,typeof(lat2d)  ,getvardims(lat2d))    
filevardef(fout, "ASI_Ice_Concentration"    ,typeof(sic)    ,getvardims(sic))          

filevarattdef(fout,"time" ,time)                     ; copy lev attributes
filevarattdef(fout,"x"  ,x)                     ; copy lev attributes
filevarattdef(fout,"y"  ,y)                     ; copy lat attributes
filevarattdef(fout,"lon2d"  ,lon2d)                     ; copy lon attributes
filevarattdef(fout,"lat2d"   ,lat2d)                      ; copy PS attributes
filevarattdef(fout,"ASI_Ice_Concentration",sic)                     ; copy TOPOG attributes


setfileoption(fout,"DefineMode",False)
;
fout->time       = (/time/)
fout->x       = (/x/)
fout->y       = (/y/)
fout->lon2d    = (/lon2d/)
fout->lat2d    = (/lat2d/)
fout->ASI_Ice_Concentration      = (/sic/)


end
