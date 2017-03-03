function A = point2tsmodis(YEARS,LOC,NAME,DIR_STACK)
% A = point2tsmodis(YEARS,LOC,NAME,DIR_STACK)
% 
% INPUT
%   YEARS      : Interval or list of yearly stacks from which extract data
%   LOC        : Full file name in which coordinates of one or more points
%                can be found. Use the same reference system used to store
%                stacks, i.e. EPSG:4326
%                List the two coordinates of each point on each row,
%                without colum header.
%   NAME       : The string which identifies the name of the stack to
%                query. It is assumed that the stack has base name such as:
%                   *_A2001_MOD13Q1.006.tif
%                where * can be one of NDVI, VIQuality or any other dataset
%                name.
%                   
%   DIR_STACK  : Position of the stack on HDD
% 
% OUTPUT
%   A          : Time-series (TS) of MODIS singnal extracted from stack.
%                Data in A is organized in this way:
%                   > 1st dim : DOYs in the year (23 in MODIS)
%                   > 2nd dim : No. of geospatial points (in LOC file)
%                   > 3rd dim : Years
% 
% DESCRIPTION
%   This function extracts data from the stack grids at the point(s)
%   indicated in LOC.
% 
% EXAMPLE
%   VIQ = point2tsmodis( 2001:2016, 'lonlat_pits_4326.txt', 'VIQuality' )
%   VIQ = point2tsmodis( 2001:2016, 'lonlat_pits_4326.txt', 'VIQuality', '/media/DATI/db-backup/MODIS/stack' )

%% CHECKS
if nargin<4
    DIR_STACK='/media/DATI/db-backup/MODIS/stack';
end
%% PARS
DOY_LIST    = { '001';'017';'033';'049';'065';'081';'097';'113';'129';...
                '145';'161';'177';'193';'209';'225';'241';'257';'273';...
                '289';'305';'321';'337';'353'; };
%% GDAL commands
%             gdallocationinfo( fullfile(DIR_MODIS,'stack',['NDVI_A',num2str(YEARS(1)),'_MOD13Q1.006.tif']) ,...
%                               fullfile(WDIR,'lonlat_pits.txt'), ...
%                             ) ...
gdallocationinfo = @(iTif,loc) ['gdallocationinfo -geoloc -valonly ', ...
                                    iTif,' < ',loc];
%% PRE
% load list of geospatial points (to know the number of points)
Points = load( LOC );
%% main
A = NaN(numel(DOY_LIST),size(Points,1),numel(YEARS));
for ii = 1:numel(YEARS)
    [status,reply] = system( ...
                gdallocationinfo( ...
            fullfile(DIR_STACK,[NAME,'_A',num2str(YEARS(ii)),'_MOD13Q1.006.tif']) ,...
                          LOC   ) ...
                           );
    if status
        error('%s',reply)
    end
    A(:,:,ii) = reshape( str2num(reply),numel(DOY_LIST),size(Points,1) ); %#ok<ST2NM>
end
%% return
end
