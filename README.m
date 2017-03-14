% The modis package under MatLab was developed to manage Satellite data
% coming from MODIS.
% 
% General overview on MODIS data:
%   http://sugar.coas.oregonstate.edu/ORSOO/MODIS/workshop/tutorials/MODIStutorials.pdf
% 
% Reading .HDF files from within MatLab:
%   http://vgl-ait.org/cvwiki/doku.php?id=matlab:tutorial:modis_dataset_manipulation_in_matlab
%   http://hdfeos.org/zoo/LAADS/MOD08_D3_Cloud_Fraction_Liquid.m
%   https://it.mathworks.com/matlabcentral/fileexchange/2611-earth-observing-system-data-visualization/content/eos_example_1.m
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
% A detailed description and help for interpretation of quality of VI
% signals, see the README file at:
%   /media/DATI/db-backup/MODIS/quality-example
% in which all details are highlighted.
% 
% 250m/500m  16 days VI Product – HDF-EOS V2 MODIS VEGETATION INDICES HDF
% File Specification
%   https://ladsweb.nascom.nasa.gov/api/v1/filespec/collection=6&product=MOD13Q1
% 
% MatLab tutorial on plot NDVI image:
%   https://www.youtube.com/watch?v=nuUwXx_aO_c
% 
% To download using urlwrite:
%   http://it.mathworks.com/matlabcentral/fileexchange/47329-measures/content/measures/measures_data.m
% 
% The program should be run under MatLab r2014a version.
% The problem with last version (r2016b) may be in the folder:
%   /usr/local/MATLAB/R2016b/sys/os/glnxa64/
% in which the lib libstdc++.so.6 is different from the file:
%   /usr/local/MATLAB/R2014a/sys/os/glnxa64/libstdc++.so.6
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
%                        See these alternative methods to download MODIS data:
%                           > cURL / wget (https://nsidc.org/support/faq/what-options-are-available-bulk-downloading-data-https-earthdata-login-enabled)
%                           > pyMODIS (http://www.pymodis.org/)
%                           > on-the-fly from-scratch to-be-converted script (http://www.gisremotesensing.com/2010/06/getting-modis-image-automatically-from.html)
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
%                        ROI. It was planned to perform also the stack
%                        creation, but the extraction of info from .vrt
%                        does not work and the gdal_merge.py does not work
%                        on gpu-pedology. This way I created the
%                        stackcreatemodis script to deal with this task.
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
%                            This function is dedicated to the creation of
%                            stacks using the gdal_merge.py function. The
%                            issue at now is that it does not work on
%                            gpu-pedology, hence a list of commands is
%                            saved to run the process on the ftp-pedology.
%                            In a future version I have to delete the
%                            creation of stack from convertmodis and
%                            specilize stackcreatemodis to perform this
%                            operation.
% 
%   (5) countmodis.m::   It checks for missing data. Can be used to
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

% to update giulange project with the original project, use the following:
git remote -v
git remote add upstream https://github.com/jgomezdans/get_modis.git % only once
git remote -v
git fetch upstream
git checkout master
git merge upstream/master

% example of using original project function:
~/git/get_modis/./get_modis.py -u giulange -P XMa-q9t-pTt-dZC -v -s MOLT -p MOD13Q1.006 -y 2016 -t h18v04 -o /media/DATI/db-backup/MODIS/hdf-it/ -b 100 -e 120

