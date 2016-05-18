% The modis package under MatLab was developed to manage Satellite data
% coming from MODIS.
% There are three scripts each with own parameters to be configured. In
% order of execution there are:
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
% The gdal package should be already installed on the computer, typically
% at:
%   ll /usr/bin/*gdal*
%   ll /usr/local/bin/*gdal*

