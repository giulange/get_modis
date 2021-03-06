
# export sigle MODIS band from original hdf to vrt:
gdalbuildvrt /media/DATI/db-backup/MODIS/vrt/singleBand.vrt 'HDF4_EOS:EOS_GRID:"/media/DATI/db-backup/MODIS/hdf-it/MOD13Q1.A2001145.h19v04.006.2015143102300.hdf":MODIS_Grid_16DAY_250m_500m_VI:250m 16 days NDVI'

# convert previous single band from vrt to tif:
gdal_translate -of GTiff -co "COMPRESS=LZW" -co "TILED=YES" /media/DATI/db-backup/MODIS/vrt/singleBand.vrt /media/DATI/db-backup/MODIS/tif/singleBand.tif

# example of stack creation:
gdal_merge.py -seperate NDVI_A2001001_MOD13Q1.006.tif NDVI_A2001017_MOD13Q1.006.tif NDVI_A2001033_MOD13Q1.006.tif NDVI_A2001049_MOD13Q1.006.tif NDVI_A2001065_MOD13Q1.006.tif NDVI_A2001081_MOD13Q1.006.tif NDVI_A2001097_MOD13Q1.006.tif NDVI_A2001113_MOD13Q1.006.tif NDVI_A2001129_MOD13Q1.006.tif NDVI_A2001145_MOD13Q1.006.tif NDVI_A2001161_MOD13Q1.006.tif NDVI_A2001177_MOD13Q1.006.tif NDVI_A2001193_MOD13Q1.006.tif NDVI_A2001209_MOD13Q1.006.tif NDVI_A2001225_MOD13Q1.006.tif NDVI_A2001241_MOD13Q1.006.tif NDVI_A2001257_MOD13Q1.006.tif NDVI_A2001273_MOD13Q1.006.tif NDVI_A2001289_MOD13Q1.006.tif NDVI_A2001305_MOD13Q1.006.tif NDVI_A2001321_MOD13Q1.006.tif NDVI_A2001337_MOD13Q1.006.tif NDVI_A2001353_MOD13Q1.006.tif -o NDVI_A2001-MOD13Q1.006.tif

# extract NDVI value in Ercolano from geotiff:
gdallocationinfo -geoloc NDVI_A2004129_MOD13Q1.006.tif 14.349074 40.800515

gdallocationinfo -geoloc -valonly /media/DATI/db-backup/MODIS/stack/NDVI_A2001_MOD13Q1.006.tif 14.459074 40.800515


