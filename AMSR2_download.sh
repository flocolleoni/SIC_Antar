#!/bin/sh

# Get the date of yesterday 
 let NOW=$(date -v -24H +"%Y%m%d")
 



#Download the data files

# wget --no-check-certificate https://seaice.uni-bremen.de/data/amsr2/asi_daygrid_swath/s3125/2017/nov/RossSea/asi-AMSR2-s3125-$NOW-v5.hdf

 wget --no-check-certificate https://seaice.uni-bremen.de/data/amsr2/asi_daygrid_swath/s3125/2018/jan/RossSea/asi-AMSR2-s3125-$NOW-v5.hdf   
