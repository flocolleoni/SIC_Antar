#/bin/sh

let i=1
let nyear=2016

#filename='nt_20161023_f18_nrt_s.bin'



  LIST=`ls nt_2016*.bin`

 for j in $LIST; do

    ncl "filin=\"$j\"" read_bin_SSMI.ncl

    
    cdo setcalendar,standard -settaxis,2016-01-01,12:00,1day tmp.nc tmp2.nc
    
    
    if [ $i -lt 10 ] ; then
       mv tmp2.nc tmp_000$i.nc
    elif [ $i -lt 100 ] ; then
       mv tmp2.nc tmp_00$i.nc
    elif [ $i -lt 1000 ] ; then
       mv tmp2.nc tmp_0$i.nc  
    fi        

   let i=$i+1

 done

  rm tmp.nc
  
  ncrcat tmp*.nc seaice_tmp.nc
  cdo setcalendar,standard -settaxis,2016-01-01,12:00,1day seaice_tmp.nc seaice_daily_$nyear.nc
  
  rm *tmp* 
