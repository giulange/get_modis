% The modis package under MatLab was developed to manage Satellite data
% coming from MODIS.
% 
% The data (not only MODIS) are stored by USGS at:
%   https://ladsweb.modaps.eosdis.nasa.gov/missions-and-measurements/
%   https://lpdaac.usgs.gov/data_access/data_pool
% 
% "Vegetation Indices 16-Day L3 Global 250m" MODIS data are called:
%       > MOD13Q1 Terra (=MOLT)
%       > MYD13Q1 Aqua  (=MOLA)
% See this link to retrieve Terra data:
%   https://e4ftl01.cr.usgs.gov/MOLT/
% 
% To understand how to choose the requied "MODIS product name with
% collection tag at the end", see these links:
%   https://ladsweb.modaps.eosdis.nasa.gov/missions-and-measurements/
%   https://ladsweb.modaps.eosdis.nasa.gov/about/purpose/MODIS-Land-Proc-Flow.png
%   
% A detail User's Guide for MOD13Q1.006 is at:
%   https://lpdaac.usgs.gov/sites/default/files/public/product_documentation/mod13_user_guide.pdf
%   http://www.ctahr.hawaii.edu/grem/mod13ug/sect0005.html
%   https://modis.gsfc.nasa.gov/data/atbd/atbd_mod13.pdf
% 
% A detailed description of the MOD13Q1.006 product is at:
%   https://lpdaac.usgs.gov/node/844
% 
% 250m/500m  16 days VI Product – HDF-EOS V2 MODIS VEGETATION INDICES HDF
% File Specification
%   https://ladsweb.nascom.nasa.gov/api/v1/filespec/collection=6&product=MOD13Q1
% 
% 
% There are five scripts each with own parameters to be configured.
% In order of execution there are:
%   (1) downmodis.m   :: It is based on the get_modis.py script included in
%                        the folder. It downloads hdf files and stores them
%                        in a user defined path. The user can select tiles
%                        accordindg to a ROI, years and start/end DOY.
%                        fnc() ––> get_modis.py
%                        pars  ––> product, start/end DOY, MODIS platform,
%                                  years, tiles
% 
%   (2) mosaicmodis.m :: It extracts from hdf files the required band (e.g.
%                        NDVI or EVI) and stitches together the tiles of
%                        the same DOY. The user can select year, band,
%                        tiles, start/end DOY.
%                        The output are .vrt files, one for each complete
%                        DOY required by user.
%                        fnc() ––> gdalinfo_getBandName=@gdalinfo()
%                                  gdalbuildvrt_createMosaic=@gdalbuildvrt()
%                        pars  ––> product, start/end DOY, years, tiles,
%                                  band
% 
%   (3) convertmodis.m:: It converts the .vrt files into GTiff (or other
%                        format as required) applying the required
%                        reference system. The developer is planning to set
%                        an option with which create yearly stacks for a
%                        ROI.
%               case#1
%                        fnc() ––> gdalbuildvrt=@gdalbuildvrt()
%                                  gdal_translate=@gdal_translate()
%               case#2
%                        fnc() ––> gdalwarp=@gdalwarp()
%                                  gdal_merge=@gdal_merge.py()
%               any
%                        pars  ––> product, start/end DOY, years, tiles,
%                                  band
% 
%   (4) stackcreatemodis.m:: It aggregates the geoTiff NDVI (23) maps of
%                            the same year in the same stack (e.g.
%                            NDVI_A2001_MOD13Q1.006.tif).
% 
%   (5) convertmodis.m:: It checks for missing data. Can be used to
%                        understand whether to import new data from the
%                        server or not.
% 
% The gdal package should be already installed on the computer, typically
% at:
%   ll /usr/bin/*gdal*
%   ll /usr/local/bin/*gdal*

% Run MatLab without desktop:
matlab -nojvm -nodisplay -nosplash

% Run a matlab script by command line:
matlab -nojvm -nodisplay -nosplash < stackcreatemodis.m

% To run the batch script executing gdal_merge.py on ftp-pedology, I need
% to substitute a string in bash script:
sudo sed -i 's/DATI/FTP/g' batch_gdalmerge
% Run the above coomand being at
giuliano@ftp-pedology-unina:/media/FTP/db-backup/MODIS/tif

% to check the stacks created, you can:
ls *A20??_MOD* -lah

