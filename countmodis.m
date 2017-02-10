%% PARs
%% -- NON-PARAMETRIC
PRODUCT     = 'MOD13Q1.006';
DOY_LIST    = { '001';'017';'033';'049';'065';'081';'097';'113';'129';...
                '145';'161';'177';'193';'209';'225';'241';'257';'273';...
                '289';'305';'321';'337';'353'; };
%% -- PARAMETRIC
% DIR_IN      = '/media/DATI/db-backup/MODIS/vrt';
%DIR_IN      = '/media/DATI/db-backup/MODIS/tif';
DIR_IN      = '/media/DATI/db-backup/MODIS/hdf-it';
YEARS       = 2001:2017;% 2014
BAND        = 'NDVI';% {NDVI, VIQuality, }
FORMAT      = 'hdf';% output format for end-product files {vrt,tif,hdf}
TILES       = {'h18v04','h18v05','h19v04','h19v05'};% considered only in case of hdf
%% pre
% e.g. NDVI_A2006033_MOD13Q1.006.vrt
LIST        = dir( fullfile(DIR_IN, [BAND,'_A*_',PRODUCT,'.',FORMAT]) );
LIST        = {LIST.name}';
%% main

% break-down the list:
Fp      = cell2mat( strfind(LIST,'_') );
if sum( diff(Fp(:,1)) ) || sum( diff(Fp(:,2)) )
    error('The code needs that every file has the same position of "." in LIST!')
end

% available years:
L       = char(LIST);
UL      = unique(cellstr(L(:,Fp(1,1)+2:Fp(1,2)-4)));
% find unique years in the DIR:
uaY     = str2double(UL);

% check whether there are some gaps in available years:
[Fy,iA,iB] = setxor(uaY,YEARS);
if ~isempty(iB)
    fprintf('Following years are missing:\n')
    fprintf('\t{ ')
    for ii=1:numel(iB),fprintf('%d ',YEARS(iB(ii))),end
    fprintf(' }\n\n')
end

% display the general msg:
fprintf('Missing DOYs\n');

for y=1:numel(YEARS)
    if sum(YEARS(iB)==YEARS(y))
        % Nothing to do, because it already printed missing years!
        continue
    end
        
    % set current year:
    yLIST = dir( fullfile(DIR_IN, [BAND,'_A',num2str(YEARS(y)),'*_',PRODUCT,'.',FORMAT]) );
    yLIST = {yLIST.name}';
    
    % Available days:
    uaDays = cell(size(yLIST));
    for ii=1:numel(yLIST)
        if ~isempty( strfind(yLIST{ii},['A',num2str( YEARS(y) )]) )
            uaDays{ii} = yLIST{ii}(Fp(1,1)+6:Fp(1,2)-1);
        else
            uaDays{ii} = '';
        end
    end

    % check consistency of DOYs in both the reference list and available
    % files:
    [Fdoy,iAd,iBd] = setxor(uaDays,DOY_LIST);
    if ~isempty(Fdoy)
        % print current year:
        fprintf('  %d\n',YEARS(y))
    end
    % Case #1 :: DOYs that user requires but are missing on HDD
    %            (i.e. DOYs present in DOY_LIST and not available on HDD)
    if ~isempty(iBd)
        fprintf('    %s: { ','expected by user, but missing on HDD')
        for jj = 1:numel(iBd)
            fprintf('''%s'';', DOY_LIST{iBd(jj)} )
        end
        fprintf(' }\n');
    end
    % Case #2 :: DOYs that are found on HDD but user didn't require
    if ~isempty(iAd)
        fprintf('    %s: { ','found on HDD, but user didn''t require')
        for jj = 1:numel(iBd)
            fprintf('''%s'';', uaDays{iAd(jj)} )
        end
        fprintf(' }\n');
    end    
end


