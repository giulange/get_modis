%% mosaic all tiles of the same day for all days found in folder
% See this useful link:
%   https://jgomezdans.github.io/stitching-together-modis-data.html
%% PARs
%% -- NON-PARAMETRIC
DIR_OUT     = '/media/DATI/db-backup/MODIS/vrt';
%% -- PARAMETRIC
DIR_IN      = '/media/DATI/db-backup/MODIS/hdf-it/snowcover';
PRODUCT     = 'MYD10A1.006';% { MOD13Q1.006 , MYD10A1.006 ,   }
YEARS       = 2002:2016;% {2004; 2001:2017; ...}
TILES       = {'h18v04','h18v05','h19v04','h19v05'};
BAND        = 'NDSI_Snow_Cover';%
%        ...:: MOD13Q1.006 ::...
%                 { NDVI,EVI, VI Quality, red reflectance, NIR reflectance, 
%                   blue reflectance, MIR reflectance, view zenith
%                   angle, sun zenith angle, relative azimuth angle,
%                   composite day of the year, pixel reliability }
%        ...:: MYD10A1.006 ::...
%                 { NDSI_Snow_Cover, NDSI_Snow_Cover_Basic_QA,
%                   NDSI_Snow_Cover_Algorithm_Flags_QA, NDSI,
%                   Snow_Albedo_Daily_Tile, orbit_pnt, granule_pnt }
SDOY        = 1;
EDOY        = 366;% { 2, 366 }
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

% Produce a mosaic of this kind:
% gdalbuildvrt mosaik.vrt 'HDF4_EOS:EOS_GRID:"MOD13Q1.A2014225.h18v04.006.2015289162913.hdf":MODIS_Grid_16DAY_250m_500m_VI:250m 16 days NDVI' 'HDF4_EOS:EOS_GRID:"MOD13Q1.A2014225.h18v05.006.2015289162858.hdf":MODIS_Grid_16DAY_250m_500m_VI:250m 16 days NDVI'
%gdalbuildvrt = @(y,doy) ['gdalbuildvrt ',fullfile(DIR_OUT,[BAND,'_A',num2str(y),doy,'.vrt'])];
BD = BAND; BD(isspace( BAND ))=[];
gdalbuildvrt_createMosaic = @(y,doy) ...
                    ['gdalbuildvrt ',fullfile(DIR_OUT,  ...
                    	[BD,'_A',num2str(y),doy,'_',PRODUCT,'.vrt']) ...
                    ];
% The gdalbuildvrt_createMosaic function handle is hereafter used to cat
% every tile belonging to the same day!
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
            %fprintf('\tDOY=%s skipped!\n',uaDays{d})
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
            [status,reply] = system( gdalinfo_getBandName(YEARS(y),uaDays{d},TILES{t}) );
            if status, error('%s',reply), end
            % Check if more bands have the same base name:
            %  (for instance this happens for MYD10A1.006 products where
            %   more bands show the initial string NDSI_Snow_Cover in the
            %   band name!)
            chk  = greadtext(reply, ':', '', '', 'textsource');
            if size(chk,1)==1
                % reply = reply;
            else
                Fchk = strcmp(chk,BAND);
                switch sum(Fchk(:))
                    case 1
                        %good!
                        % select the proper BAND name from the list found
                        [rr,~] = find( Fchk );
                        reply2 = chk{rr,1};
                        for ii=2:size(chk,2)
                            reply2 = [reply2,':',chk{rr,ii}]; %#ok<AGROW>
                        end
                        reply = reply2;
                    case 0
                        error('Current BAND name (%s) not found.',BAND)
                    otherwise
                        error('More BAND names (%s) were found.',BAND)
                end
            end
            % use the full & unique band name found:
            fprintf('%s\n',reply)
            % remove trailing blanks from end of string
            reply=deblank(reply);
            % extract band name:
            Feq=strfind(reply,'=');
            %band_tiles{t}=reply(Feq+1:end);
            
            % |02| gdalbuildvrt mosaik.vrt ...
            % mosaic with gdal:
            str = [str,' ''',reply(Feq+1:end),'''']; %#ok<AGROW>
        end
        fprintf('Running...\n\t%s\n', str )
        [a,reply] = system( str );
        fprintf('%s\n',reply)
    end
end