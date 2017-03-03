%% mosaic all tiles of the same day for all days found in folder
% See this useful link:
%   https://jgomezdans.github.io/stitching-together-modis-data.html

%% PARs
%% -- NON-PARAMETRIC
DIR_IN      = '/media/DATI/db-backup/MODIS/hdf-it';
DIR_OUT     = '/media/DATI/db-backup/MODIS/vrt';
PRODUCT     = 'MOD13Q1.006';
SDOY        = 1;
EDOY        = 366;
%% -- PARAMETRIC
YEARS       = 2001:2017;% {2004; 2001:2017; ...}
TILES       = {'h18v04','h18v05','h19v04','h19v05'};
BAND        = 'VI Quality';% 
%                 { NDVI,EVI, VI Quality, red reflectance, NIR reflectance, 
%                   blue reflectance, MIR reflectance, view zenith
%                   angle, sun zenith angle, relative azimuth angle,
%                   composite day of the year, pixel reliability }
%% pre
Fpoint      = strfind(PRODUCT,'.');
LIST        = dir( fullfile(DIR_IN,[PRODUCT(1:Fpoint-1),'*',PRODUCT(Fpoint+1:end),'*.hdf']) );
LIST        = {LIST.name}';
%% original commands

% Get the full name of layer and band in hdf:
% gdalinfo /media/DATI/db-backup/MODIS/trial/MOD13Q1.A2001001.h18v04.006.2015140084914.hdf | grep NDVI | grep '_NAME'

gdalinfo_getBandName = @(y,doy,t) ...
                       ['gdalinfo ', fullfile(DIR_IN, ...
                         [PRODUCT(1:Fpoint-1),'.A',num2str(y),doy,'.',t,'.',...
                          PRODUCT(Fpoint+1:end),'*.hdf']),...
                        ' | grep "',BAND,'" | grep ''_NAME'''];

% Produce the mosaic:
% gdalbuildvrt mosaik.vrt 'HDF4_EOS:EOS_GRID:"MOD13Q1.A2014225.h18v04.006.2015289162913.hdf":MODIS_Grid_16DAY_250m_500m_VI:250m 16 days NDVI' 'HDF4_EOS:EOS_GRID:"MOD13Q1.A2014225.h18v05.006.2015289162858.hdf":MODIS_Grid_16DAY_250m_500m_VI:250m 16 days NDVI'
%gdalbuildvrt = @(y,doy) ['gdalbuildvrt ',fullfile(DIR_OUT,[BAND,'_A',num2str(y),doy,'.vrt'])];
BD = BAND; BD(isspace( BAND ))=[];
gdalbuildvrt_createMosaic = @(y,doy) ...
                    ['gdalbuildvrt ',fullfile(DIR_OUT,  ...
                    	[BD,'_A',num2str(y),doy,'_',PRODUCT,'.vrt']) ...
                    ];
%% batch mosaic
% The script mosaics the tiles of the same day in one vrt file which can be
% easily managed with gdalwarp to apply custom reference system and file
% format (e.g. geotiff).

% Example file is:
%   MOD13Q1.A2001001.h18v04.006.2015140084914.hdf

% loop for every time element:
Fp      = cell2mat( strfind(LIST,'.') );
if sum( diff(Fp(:,1)) ) || sum( diff(Fp(:,2)) )
    error('The code needs that every file has the same position of "." in LIST!')
end

L       = char(LIST);
UL      = unique(cellstr(L(:,Fp(1,1)+1:Fp(1,2)-1)));

% available years:
aYears  = zeros(size(UL));
for ii=1:numel(UL)
    aYears(ii) = str2double( UL{ii}(2:5) );
end

% find unique years in the DIR:
uaY     = unique(aYears);

% check whether there are some gaps:
[Fy,iA,iB] = setxor(uaY,YEARS);
if ~isempty(iB)
    warning('Following years are missing:')
    fprintf('\t')
    for ii=1:numel(iB),fprintf('%d ',YEARS(iB(ii))),end
    fprintf('\n\n')
end

% mosaic required tiles for each day
for y=1:numel(YEARS)
    
    % skip the unavailable year:
    if find(YEARS(y)==YEARS(iB))
        fprintf('Year=%d skipped!\n',YEARS(y))
        continue
    end
    
    % display the current year:
    fprintf('YEAR: %d\n',YEARS(y));

    % Available days:
    aDays = cell(size(LIST));
    for ii=1:numel(LIST)
        if ~isempty(strfind(LIST{ii},['A',num2str( YEARS(y) )]))
            aDays{ii} = LIST{ii}(Fp(1,1)+6:Fp(1,2)-1);
        else
            aDays{ii} = '';
        end
    end
    % Unique available days:
    uaDays = unique(aDays);
    if isempty(uaDays{1}), uaDays(1)=[]; end
    
    % loop on all available days in folder and skip those days outside the
    % range SDOY:EDOY
    for d=1:numel(uaDays)
        % if available day is outside defined range, skip
        if str2double(uaDays{d})<SDOY || str2double(uaDays{d})>EDOY
            fprintf('\tDOY=%s skipped!\n',uaDays{d})
            continue
        end    
        fprintf('\tIncluding DOY=%s ...\n',uaDays{d})
        
        Ftiles = strfind(aDays,uaDays{d});
        
        % for available year, find the day
        aTiles = cell(size(TILES));
        tt=0;
        for t=1:numel(Ftiles)
            if isempty(Ftiles{t}), continue, end
            tt = tt+1;
            aTiles{tt} = LIST{t}(Fp(1,2)+1:Fp(1,3)-1);
        end
        
        % check that available tiles in current year and doy are exactly
        % those tiles user need:
        [Ft,iA,iB] = setxor(aTiles,TILES);
        if ~isempty(iB)
            warning('The following tiles are missing in year=%d and DOY=%s\n\n')
            for jj=1:numel(iB),fprintf('\t%s ',TILES{iB}), end
            fprintf('\n')
            continue
        end
        
        % |02| gdalbuildvrt mosaik.vrt ...
        str = gdalbuildvrt_createMosaic(YEARS(y),uaDays{d});
        % Collect correct band from each tile
        %band_tiles = cell(size(TILES));
        for t=1:numel(TILES)
            % |01| gdalinfo MOD13Q1.A2014225.h18v04.006.2015289162913.hdf| grep NDVI | grep '_NAME'
            fprintf('Running...\n\t%s\n', gdalinfo_getBandName(YEARS(y),uaDays{d},TILES{t}) )
            [~,reply] = system( gdalinfo_getBandName(YEARS(y),uaDays{d},TILES{t}) );
            fprintf('%s\n',reply)
            % remove trailing blanks from end of string
            reply=deblank(reply);
            % extract band name:
            Feq=strfind(reply,'=');
            %band_tiles{t}=reply(Feq+1:end);
            
            % |02| gdalbuildvrt mosaik.vrt ...
            % mosaic with gdal:
            str = [str,' ''',reply(Feq+1:end),''''];
        end
        fprintf('Running...\n\t%s\n', str )
        [a,reply] = system( str );
        fprintf('%s\n',reply)
    end
end