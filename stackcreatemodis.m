%% PARs
%% -- NON-PARAMETRIC
PRODUCT     = 'MOD13Q1.006';
DOY_LIST    = { '001';'017';'033';'049';'065';'081';'097';'113';'129';...
                '145';'161';'177';'193';'209';'225';'241';'257';'273';...
                '289';'305';'321';'337';'353'; };
%% -- PARAMETRIC
DIR_IN      = '/media/DATI/db-backup/MODIS/tif';
DIR_OUT     = '/media/DATI/db-backup/MODIS/tif';
YEARS       = 2001:2016;
BAND        = 'NDVI';% which data to be extracted by original .hdf files
iFORMAT      = 'tif';% input  format for end-product files
oFORMAT      = 'tif';% output format for end-product files
%% pre
Fpoint      = strfind(PRODUCT,'.');
LIST        = dir( fullfile(DIR_IN, [BAND,'_A*_',PRODUCT,'.',iFORMAT]) );
LIST        = {LIST.name}';
% typeOf: 'NDVI_A2001001_MOD13Q1.006.vrt'

curr_dir = pwd;
cd( DIR_IN )% execute gdal_merge there to avoid 23 times the path 
%% Original commands
% |01| build the stack, mounting the GTiff together
% gdal_merge.py -seperate NDVI_A2001001_MOD13Q1.006.tif NDVI_A2001017_MOD13Q1.006.tif NDVI_A2001033_MOD13Q1.006.tif -o stack.tif
% gdal_merge.py -seperate NDVI_A2001001_MOD13Q1.006.tif NDVI_A2001017_MOD13Q1.006.tif NDVI_A2001033_MOD13Q1.006.tif NDVI_A2001049_MOD13Q1.006.tif NDVI_A2001065_MOD13Q1.006.tif NDVI_A2001081_MOD13Q1.006.tif NDVI_A2001097_MOD13Q1.006.tif NDVI_A2001113_MOD13Q1.006.tif NDVI_A2001129_MOD13Q1.006.tif NDVI_A2001145_MOD13Q1.006.tif NDVI_A2001161_MOD13Q1.006.tif NDVI_A2001177_MOD13Q1.006.tif NDVI_A2001193_MOD13Q1.006.tif NDVI_A2001209_MOD13Q1.006.tif NDVI_A2001225_MOD13Q1.006.tif NDVI_A2001241_MOD13Q1.006.tif NDVI_A2001257_MOD13Q1.006.tif NDVI_A2001273_MOD13Q1.006.tif NDVI_A2001289_MOD13Q1.006.tif NDVI_A2001305_MOD13Q1.006.tif NDVI_A2001321_MOD13Q1.006.tif NDVI_A2001337_MOD13Q1.006.tif NDVI_A2001353_MOD13Q1.006.tif -o NDVI_A2001-MOD13Q1.006.tif
gdal_merge = @(iTifs,oTif) ['gdal_merge.py -seperate ',iTifs,' ',fullfile(DIR_OUT,oTif)];
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

% check whether there are some gaps in available years:
[Fy,iA,iB] = setxor(uaY,YEARS);
if ~isempty(iB)
    warning('Following years are missing:')
    fprintf('\t')
    for ii=1:numel(iB),fprintf('%d ',YEARS(iB(ii))),end
    fprintf('\n\n')
end

% print the columns header:
fprintf('%s',repmat(' ',1,15));
for ii=1:numel(DOY_LIST),fprintf('%5s',DOY_LIST{ii}); end
fprintf('%12s\n','gdal_merge')

CMD = cell(numel(YEARS),1);
% yearly mosaic requires tiles for each day:
for y=1:numel(YEARS)
    
    % skip the unavailable year:
    if find(YEARS(y)==YEARS(iB))
        fprintf('Year=%d skipped!\n',YEARS(y))
        continue
    end

    % display the current year:
    fprintf('YEAR: %9d',YEARS(y));
    
    % set current year:
    yLIST = dir( fullfile(DIR_IN, [BAND,'_A',num2str(YEARS(y)),'*_',PRODUCT,'.',iFORMAT]) );
    yLIST = {yLIST.name}';
    
    % Available DOYs:
    uaDays = cell(size(yLIST));
    for ii=1:numel(yLIST)
        if ~isempty(strfind(yLIST{ii},['A',num2str( YEARS(y) )]))
            uaDays{ii} = yLIST{ii}(Fp(1,1)+6:Fp(1,2)-1);
        else
            uaDays{ii} = '';
        end
    end
    % check consistency of DOYs in both the reference list and available
    % files:
    [Fdoy,iAd,iBd] = setxor(uaDays,DOY_LIST);
%     % print current year:
%     if ~isempty(Fdoy),fprintf('  %d\n',YEARS(y)), end
%     % Case #1 :: DOYs that user requires but are missing on HDD
%     %            (i.e. DOYs present in DOY_LIST and not available on HDD)
%     if ~isempty(iBd)
%         fprintf('    %s: { ','expected by user, but missing on HDD')
%         for jj = 1:numel(iBd)
%             fprintf('''%s'';', DOY_LIST{iBd(jj)} )
%         end
%         fprintf(' }\n');
%     end
%     % Case #2 :: DOYs that are found on HDD but user didn't require
%     if ~isempty(iAd)
%         fprintf('    %s: { ','found on HDD, but user didn''t require')
%         for jj = 1:numel(iBd)
%             fprintf('''%s'';', uaDays{iAd(jj)} )
%         end
%         fprintf(' }\n');
%     end    

    iTifs = '';
    stopGdalMerge = false;
    for d=1:numel(DOY_LIST)
        % if required day is not available on HDD, skip
        if ~sum( strcmp(DOY_LIST{d},uaDays) )
            fprintf('%5s','err')
            stopGdalMerge = true;
            continue
        end
        
%         fprintf('%4s','*')
        % |03| gdalwarp: convert single images from .vrt to .tif
        %      take single NDVI_A2001001_MOD13Q1.006.vrt
        FILdoy = [BAND,'_A',num2str(YEARS(y)),DOY_LIST{d},'_',PRODUCT];
        tif = [FILdoy,'.tif'];
        iTifs = [iTifs,' ',tif];
%         fprintf('%1s','√')
        fprintf('%5s','*')
    end
    
    % e.g. 'NDVI_A2001-MOD13Q1.006.tif'
    % |01| create the required stack of images
    if ~stopGdalMerge
        oTif = [BAND,'_A',num2str(YEARS(y)),'_',PRODUCT,'.',oFORMAT];
        fprintf( '%5s', '*' )
        [~,reply] = system( gdal_merge(iTifs,oTif) );
        CMD{y} = gdal_merge(iTifs,oTif);
        isFine = ~isempty(strfind(reply,'100')) && ~isempty(strfind(reply,'done'));
        fprintf('%s=%d\n','fine',isFine)
    else
        fprintf('%5s%s=%d\n','','fine',0)
    end
    fprintf('\n')
end
%% temporary print in file, while gdal_merge.py does not work
fid = fopen( fullfile(DIR_IN,'batch_gdalmerge') ,'w');
fprintf(fid,'#!/bin/bash\n');
for ii=1:numel(CMD)
    if ~isempty( CMD{ii} )
        fprintf(fid,'%s\n',CMD{ii});
    end
end
fclose(fid);
clear fid
eval( ['!chmod +x ',fullfile(DIR_IN,'batch_gdalmerge')] )
%% go back to starting path
cd( curr_dir )
