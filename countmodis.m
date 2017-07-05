%% PARs
%% -- NON-PARAMETRIC
%% -- PARAMETRIC
PRODUCT     = 'MYD10A1.006';% { MOD13Q1.006 , MYD10A1.006 ,   }
BAND        = 'NDSI_Snow_Cover';% { NDVI, VIQuality, pixelreliability, NDSI_Snow_Cover }

YEARS       = 2003:2016;% 2014
% DOY_LIST    = { '001';'017';'033';'049';'065';'081';'097';'113';'129';...
%                 '145';'161';'177';'193';'209';'225';'241';'257';'273';...
%                 '289';'305';'321';'337';'353'; };
DOY_LIST=cell(366,1); for ii=1:366,DOY_LIST{ii}=sprintf('%03d',ii);end

% DIR_IN      = '/media/DATI/db-backup/MODIS/vrt';
DIR_IN      = '/media/DATI/db-backup/MODIS/tif';
% DIR_IN      = '/media/DATI/db-backup/MODIS/hdf-it/snowcover';

FORMAT      = 'tif';% output format for end-product files {vrt,tif,hdf}
TILES       = {'h18v04','h18v05','h19v04','h19v05'};% considered only in case of hdf
%% pre
switch FORMAT
    case {'vrt','tif'} % e.g. NDVI_A2006033_MOD13Q1.006.vrt
        LIST        = dir( fullfile(DIR_IN, [BAND,'_A*_',PRODUCT,'.',FORMAT]) );
        LIST        = {LIST.name}';
    case 'hdf'% e.g. MYD10A1.A2002185.h18v04.006.2016152140520.hdf
        Fpoint      = strfind(PRODUCT,'.');
        LIST        = dir( fullfile(DIR_IN,[PRODUCT(1:Fpoint-1),'*',PRODUCT(Fpoint+1:end),'*.hdf']) );
        LIST        = {LIST.name}';
end
if isempty(LIST)
    error('The list of products is empty. Check the parameters (dir,format,...)!')
end
%% main

switch FORMAT
    case {'vrt','tif'} % e.g. NDVI_A2006033_MOD13Q1.006.vrt
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
    case 'hdf'
        % loop for every time element:
        Fp      = cell2mat( strfind(LIST,'.') );
        if sum( diff(Fp(:,1)) ) || sum( diff(Fp(:,2)) )
            error('The code needs that every file has the same position of "." in LIST!')
        end
        Fp      = Fp(1,1:2);% the string A2002185 is between Fp(1) and Fp(2)
end

% available years:
L       = char(LIST);
% UL      = unique(cellstr(L(:,Fp(1)+2:Fp(2)-4)));
UL      = unique(cellstr(L(:,Fp(1)+1:Fp(2)-1)));
switch FORMAT
    case {'err'} % e.g. NDVI_A2006033_MOD13Q1.006.vrt
        % find unique years in the DIR:
        uaY     = str2double(UL);
    case {'hdf','vrt','tif'}
        % available years:
        aYears  = zeros(size(UL));
        for ii=1:numel(UL)
            aYears(ii) = str2double( UL{ii}(2:5) );
        end
        % find unique years in the DIR:
        uaY     = unique(aYears);
end

% check whether there are some gaps in available years:
[Fy,iA,iB] = setxor(uaY,YEARS);
if ~isempty(iB)
    fprintf('Following years are missing:\n')
    fprintf('\t{ ')
    for ii=1:numel(iB),fprintf('%d ',YEARS(iB(ii))),end
    fprintf(' }\n\n')
end

% display the general msg:
fprintf('----------------------\n');
fprintf(' List of missing DOYs\t\t[%s]\n',DIR_IN);
fprintf('----------------------\n');
for y=1:numel(YEARS)
    if sum(YEARS(iB)==YEARS(y))
        % Nothing to do, because it already printed missing years!
        continue
    end
        
    % set current year:
    switch FORMAT
        case {'vrt','tif'} % e.g. NDVI_A2006033_MOD13Q1.006.vrt
            yLIST = dir( fullfile(DIR_IN, [BAND,'_A',num2str(YEARS(y)),'*_',PRODUCT,'.',FORMAT]) );
            yLIST = {yLIST.name}';
        case 'hdf' % e.g. MYD10A1.A2002185.h18v04.006.2016152140520.hdf
            Fpoint      = strfind(PRODUCT,'.');
            yLIST       = dir( fullfile(DIR_IN,[PRODUCT(1:Fpoint-1),'.A',num2str(YEARS(y)),'*.',PRODUCT(Fpoint+1:end),'*.hdf']) );
            yLIST       = {yLIST.name}';
    end    
    if isempty(yLIST)
        error('The list of products is empty. Check the code!')
    end
    
    % Available days:
    uaDays = cell(size(yLIST));
    for ii=1:numel(yLIST)
        if ~isempty( strfind(yLIST{ii},['A',num2str( YEARS(y) )]) )
            uaDays{ii} = yLIST{ii}(Fp(1)+6:Fp(2)-1);
        else
            uaDays{ii} = '';
        end
    end

    % check consistency of DOYs in both the reference list and available
    % files:
    if ~leapyear(YEARS(y))
        DOY_LIST_m = DOY_LIST(1:365);% year with 365 days
    else
        DOY_LIST_m = DOY_LIST;
    end
    [Fdoy,iAd,iBd] = setxor(uaDays,DOY_LIST_m);
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
