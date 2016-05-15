%% PARs
%% -- NON-PARAMETRIC
DIR_IN      = '/media/DATI/db-backup/MODIS/vrt';
DIR_OUT     = '/media/DATI/db-backup/MODIS/tif';
PRODUCT     = 'MOD13Q1.006';
SDOY        = 1;
EDOY        = 366;
%% -- PARAMETRIC
YEARS       = 2001:2002;
BAND        = 'NDVI';
REFSYST     = 'EPSG:4326';
FORMAT      = 'GTiff';
%% pre
Fpoint      = strfind(PRODUCT,'.');
LIST        = dir( fullfile(DIR_IN, [BAND,'_A*_',PRODUCT,'.vrt']) );
LIST        = {LIST.name}';
FIL_LIST    = fullfile(DIR_OUT,'file_list.txt');
% typeOf: 'NDVI_A2001001_MOD13Q1.006.vrt'
%% Original commands

% *** create a yearly dataset of bands ***
% |01| transform 'NDVI_A2001001_MOD13Q1.006.vrt' into 'NDVI_A2001_MOD13Q1.006.vrt'
% gdalbuildvrt -separate -input_file_list file_list.txt NDVI_A2001_MOD13Q1.006.vrt
gdalbuildvrt = @(vrt) ['gdalbuildvrt -separate -input_file_list ', ...
                       FIL_LIST,' -a_srs ',REFSYST,' ',fullfile(DIR_IN,vrt)];
% file_list.txt ––> list of 'NDVI_A2001xxx_MOD13Q1.006.vrt'

% |02| set ref.syst (4326) & convert (GTiff) & compress
% gdal_translate -of GTiff -co "COMPRESS=LZW" -co "TILED=YES" MOD13Q1.006_2004.vrt MOD13Q1.006_2004.tif
gdal_translate = @(vrt,tif) ['gdal_translate -of ',FORMAT, ...
                             ' -co "COMPRESS=LZW" -co "TILED=YES" ', ...
                             fullfile(DIR_IN,vrt),' ',fullfile(DIR_OUT,tif)];

% *** old-one, used as further reference ***
% gdalwarp -of GTiff -t_srs "EPSG:4326" mosaik.vrt mosaik.tif

%% batch conversion

% break-down the list:
Fp      = cell2mat( strfind(LIST,'_') );
if sum( diff(Fp(:,1)) ) || sum( diff(Fp(:,2)) )
    error('The code needs that every file has the same position of "." in LIST!')
end

L       = char(LIST);
UL      = unique(cellstr(L(:,Fp(1,1)+2:Fp(1,2)-4)));
% find unique years in the DIR:
uaY     = str2double(UL);

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

    % set current year:
    yLIST = dir( fullfile(DIR_IN, [BAND,'_A',num2str(YEARS(y)),'*_',PRODUCT,'.vrt']) );
    yLIST = {yLIST.name}';
    
    % Available days:
    uaDays = cell(size(yLIST));
    for ii=1:numel(yLIST)
        if ~isempty(strfind(yLIST{ii},['A',num2str( YEARS(y) )]))
            uaDays{ii} = yLIST{ii}(Fp(1,1)+6:Fp(1,2)-1);
        else
            uaDays{ii} = '';
        end
    end
    %if isempty(uaDays{1}), uaDays(1)=[]; end

    % open file
    fid = fopen(FIL_LIST,'w');

    % loop on all available days in folder and skip those days outside the
    % range SDOY:EDOY
    for d=1:numel(uaDays)
        % if available day is outside defined range, skip
        if str2double(uaDays{d})<SDOY || str2double(uaDays{d})>EDOY ...
           || isempty(uaDays{d})
            fprintf('DOY=%s skipped!\n',uaDays{d})
            continue
        end
        
        fprintf(fid,'%s\n',fullfile(DIR_IN,yLIST{d}));
    end
    fclose(fid);
    clear fid;
    
    % |01| gdalbuildvrt:
    % 'NDVI_A2001_MOD13Q1.006.vrt'
    vrt = [BAND,'_A',num2str(YEARS(y)),'_',PRODUCT,'.vrt'];
    [~,reply] = system( gdalbuildvrt( vrt ) );
    fprintf('%s\n',reply);

    % |02| gdal_translate
    tif = [BAND,'_A',num2str(YEARS(y)),'_',PRODUCT,'.tif'];
    [~,reply] = system( gdal_translate( vrt,tif ) );
    fprintf('%s\n',reply)
    
    % delete file list .txt:
    delete(FIL_LIST)
    
end

