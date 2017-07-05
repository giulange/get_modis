function [A,M] = point2tsmodis(PRODUCT,BAND,YEARS,DOYS,LOC,WDIR,FORMAT)
% A = point2tsmodis(PRODUCT,BAND,YEARS,DOYS,LOC,WDIR,FORMAT)
% 
% NOTES
%   An example of valid filename is
%       "NDSI_Snow_Cover_A2003001_MYD10A1.006.tif", which corresponds to
%       "[BAND]_A[YEARS(ii)][DOYS(jj)]_[PRODUCT].[FORMAT]
% 
% DESCRIPTION
%   This function reads all the files that match PRODUCT, BAND and FORMAT and
%   creates a composite time series (ts) in which each geospatial location
%   has a value for the BAND variable coming from a single raster file.
%   This means that this function is able to stack values dealing with
%   files in which each file stores one band corresponding to one DOY (i.e.
%   it needs 366 files to stack the ts for a single year!).
% 
% INPUT
%   PRODUCT    : The product (such as MYD10A1.006) downloaded from a given
%                satellite/platform. It includes also the version (e.g.
%                006).
%   BAND       : The string which identifies the name of the variable to
%                query. It can be one of NDVI, VIQuality, NDSI_Snow_Cover
%                or any other dataset name.
%   YEARS      : Interval or list of years within which extract data.
%   DOYS       : List of Days-Of-Year to be considered when retrieving the
%                data on HDD.
%   LOC        : Full file name in which coordinates of one or more points
%                can be found. Use the same reference system used to store
%                stacks, i.e. EPSG:4326
%                List the two coordinates of each point on each row,
%                without colum header.
%   WDIR       : Position on HDD where all files can be found.
%   FORMAT     : Extension of all files to be processed.
% 
% OUTPUT
%   A          : Time-series (TS) of MODIS signal extracted from grids on
%                HDD.
%                Data in A is organized in this way:
%                   > 1st dim : DOYs in the year (23 in NDVI, 366 in Snow).
%                   > 2nd dim : No. of geospatial points (in LOC file).
%                   > 3rd dim : No. of Years.
%   M          : List of missing DOYs (structure array).
% 
% DESCRIPTION
%   This function extracts data from the stack grids at the point(s)
%   indicated in LOC.
% 
% EXAMPLE
% NDSI = point2tsmodis( 'MYD10A1.006','NDSI_Snow_Cover',2003:2016,DOYS, ...
%                       fullfile(WDIR,'lonlat_pits_4326.txt'), ...
%                       fullfile(DIR_MODIS,'tif'),...
%                       'tif'...
%                     );

%% DEFAULT
if nargin<6
    WDIR='/media/DATI/db-backup/MODIS/stack';
end
if nargin<7
    FORMAT='tif';
end
%% POINTS
Points = load( LOC );
%% PRE | copied from "countmodis.m"
% It is assumed that each file stores one band with one value for each
% geospatial location to be queried:
LIST        = dir( fullfile(WDIR, [BAND,'_A*_',PRODUCT,'.',FORMAT]) );
LIST        = {LIST.name}';

% break-down the list:
Fp      = cell2mat( strfind(LIST,'_') );
if isempty(Fp)
    error('Cannot find "_" in LIST!')
elseif sum( sum(diff(Fp))~=0 )
    error('The code needs that every file has the same position of "_" in LIST!')
end
% by-passing the previous if means that all rows are equal in Fp, then I
% consider only the first one:
Fp      = Fp(1,:);

% '_A' is needed when the '_' is used within the BAND name:
FA_     = cell2mat( strfind(LIST,'_A') );
if sum( sum(diff(FA_))~=0 )
    error('The code needs that every file has the same position of "_A" in LIST!')
end
% by-passing the previous if means that all rows are equal in Fp, then I
% consider only the first one:
FA_     = FA_(1,:);

sFp     = find(Fp==FA_);
Fp      = Fp(sFp:sFp+1);

% available years:
L       = char(LIST);
% UL      = unique(cellstr(L(:,Fp(1)+2:Fp(2)-4)));
UL      = unique(cellstr(L(:,Fp(1)+1:Fp(2)-1)));

% available years:
aYears  = zeros(size(UL));
for ii=1:numel(UL)
    aYears(ii) = str2double( UL{ii}(2:5) );
end
% find unique years in the DIR:
uaY     = unique(aYears);

% check whether there are some gaps in available years:
[Fy,iA,iB] = setxor(uaY,YEARS); %#ok<ASGLU>
if ~isempty(iB)
    fprintf('Following years are missing:\n')
    fprintf('\t{ ')
    for ii=1:numel(iB),fprintf('%d ',YEARS(iB(ii))),end
    fprintf(' }\n\n')
end

%% main

A = NaN(numel(DOYS),size(Points,1),numel(YEARS));
MISSING_INFO = struct(); mm=0;% mm counts the number of missing info!

% mosaic required tiles for each day
for y=1:numel(YEARS)
    
    % skip the unavailable year:
    if find(YEARS(y)==YEARS(iB))
        fprintf('Year=%d skipped!\n',YEARS(y))
        continue
    end

    % display the current year:
    fprintf('YEAR: %d\n',YEARS(y));

    % set current year:
    yLIST = dir( fullfile(WDIR, [BAND,'_A',num2str(YEARS(y)),'*_',PRODUCT,'.',FORMAT]) );
    yLIST = {yLIST.name}';
    if isempty(yLIST)
        error('The list of products is empty. Check the code!')
    end
    
    % Available days:
    uaDays = cell(size(yLIST));
    for ii=1:numel(yLIST)
        if ~isempty(strfind(yLIST{ii},['A',num2str( YEARS(y) )]))
            uaDays{ii} = yLIST{ii}(Fp(1)+6:Fp(2)-1);
        else
            uaDays{ii} = '';
        end
    end

    if ~leapyear(YEARS(y))
        DOY_LIST_m = DOYS(1:365);% year with 365 days
    else
        DOY_LIST_m = DOYS;
    end
    [Fdoy,iAd,iBd] = setxor(uaDays,DOY_LIST_m); %#ok<NASGU,ASGLU>
    for d=1:numel(DOY_LIST_m)
        if sum( strcmp(Fdoy, DOY_LIST_m{d}) ) == 1
            mm = mm +1;
            fprintf('Year %5d, Missing DOY %4s\n',YEARS(y),DOY_LIST_m{d})
            MISSING_INFO(mm).Year = YEARS(y);
            MISSING_INFO(mm).DOY  = str2double( DOY_LIST_m{d} );
            continue
        end
        % such as NDSI_Snow_Cover_A2003009_MYD10A1.006.tif
        FILdoy = [BAND,'_A',num2str(YEARS(y)),DOY_LIST_m{d},'_',PRODUCT,'.',FORMAT];
        
        A(d,:,y) = gdallocationinfo(fullfile(WDIR,FILdoy),LOC,true);
        
    end
end
%% OUTPUT
M = MISSING_INFO;
%% return
end
