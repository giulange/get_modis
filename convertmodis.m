%% PARs
%% -- NON-PARAMETRIC
DIR_IN      = '/media/DATI/db-backup/MODIS/vrt';
DIR_OUT     = '/media/DATI/db-backup/MODIS/tif';
% DIR_STACK   = '/media/DATI/db-backup/MODIS/stack';
%% -- PARAMETRIC
PRODUCT     = 'MYD10A1.006';% { MOD13Q1.006 , MYD10A1.006 }
BAND        = 'NDSI_Snow_Cover';% { NDVI, VIQuality, pixelreliability, NDSI_Snow_Cover }
YEARS       = 2002:2016;% { 2004, 2001:2017 }
SDOY        = 1;
EDOY        = 366;
REFSYST     = 'EPSG:4326';% target reference system to be applyed
FORMAT      = 'GTiff';% output format for end-product files
viaVRT      = false;% true:it creates a stack (via .vrt); false:one tif for each DOY, then create stack!
OVERWRITE   = false;% false:tif files already existent are skipped; true:tif are overwritten
createStack = false;% switch to skip stack creation (use the stackcreatemodis function instead)
%% pre
if viaVRT
    error(['The creation of stacks via .vrt does not work!\n',...
           'Run the other procedure using viaVRT=false.\n',...
           'After, run stackcreatemodis which creates a script to run on ftp-pedology as root.']) %#ok<UNRCH>
end
Fpoint      = strfind(PRODUCT,'.');
LIST        = dir( fullfile(DIR_IN, [BAND,'_A*_',PRODUCT,'.vrt']) );
LIST        = {LIST.name}';
FIL_LIST    = fullfile(DIR_OUT,'file_list.txt');
% typeOf: 'NDVI_A2001001_MOD13Q1.006.vrt'
%% Original commands

% *** create a yearly dataset of bands ***
% |01| transform 'NDVI_A2001001_MOD13Q1.006.vrt' into 'NDVI_A2001_MOD13Q1.006.vrt'
% gdalbuildvrt -separate -input_file_list file_list.txt NDVI_A2001_MOD13Q1.006.vrt
% gdalbuildvrt = @(vrt) ['gdalbuildvrt -separate -input_file_list ', ...
%                        FIL_LIST,' -a_srs ',REFSYST,' ',fullfile(DIR_IN,vrt)];
gdalbuildvrt = @(vrt) ['gdalbuildvrt -separate -input_file_list ', ...
                       FIL_LIST,' ',fullfile(DIR_IN,vrt)];
% file_list.txt ––> list of 'NDVI_A2001xxx_MOD13Q1.006.vrt'

% |02| set ref.syst (4326) & convert (GTiff) & compress
%      e.g. :: gdal_translate -of GTiff -co "COMPRESS=LZW" -co "TILED=YES" MOD13Q1.006_2004.vrt MOD13Q1.006_2004.tif
gdal_translate = @(vrt,tif) ['gdal_translate -of ',FORMAT, ...
                             ' -co "COMPRESS=LZW" -co "TILED=YES" ', ...
                             ' -a_srs ',REFSYST,' ',...
                             fullfile(DIR_IN,vrt),' ',fullfile(DIR_STACK,tif)];


% *** create one file per DOY ***
% |03| set ref.syst (4326) & convert (GTiff) & compress
%      e.g. :: gdal_translate -of GTiff -co "COMPRESS=LZW" -co "TILED=YES" MOD13Q1.006_2004.vrt MOD13Q1.006_2004.tif
%      The following is avoided beacuse has the same structure of case
%      **gdal_translate ––> does not work properly, since a useless
%                           reference system is written. Hence, I decided
%                           to use gdalwarp.
% gdal_translate = @(vrt,tif) ['gdal_translate -of ',FORMAT, ...
%                              ' -co "COMPRESS=LZW" -co "TILED=YES"', ...
%                              ' -a_srs ',REFSYST,' ',...
%                              fullfile(DIR_IN,vrt),' ',fullfile(DIR_OUT,tif)];
%      e.g. :: gdalwarp -of GTiff -t_srs "EPSG:4326" singleBand.vrt singleBand.tif
gdalwarp = @(vrt,tif) ['gdalwarp -of ',FORMAT, ...
                       ' -co "COMPRESS=LZW" -co "TILED=YES" ', ...
                       ' -t_srs ',REFSYST,' ', ...
                       fullfile(DIR_IN,vrt),' ',fullfile(DIR_OUT,tif)];

% |04| build the stack after, mounting the GTiff together
% gdal_merge.py -separate NDVI_A2001001_MOD13Q1.006.tif NDVI_A2001017_MOD13Q1.006.tif NDVI_A2001033_MOD13Q1.006.tif -o stack.tif
% gdal_merge.py -separate NDVI_A2001001_MOD13Q1.006.tif NDVI_A2001017_MOD13Q1.006.tif NDVI_A2001033_MOD13Q1.006.tif NDVI_A2001049_MOD13Q1.006.tif NDVI_A2001065_MOD13Q1.006.tif NDVI_A2001081_MOD13Q1.006.tif NDVI_A2001097_MOD13Q1.006.tif NDVI_A2001113_MOD13Q1.006.tif NDVI_A2001129_MOD13Q1.006.tif NDVI_A2001145_MOD13Q1.006.tif NDVI_A2001161_MOD13Q1.006.tif NDVI_A2001177_MOD13Q1.006.tif NDVI_A2001193_MOD13Q1.006.tif NDVI_A2001209_MOD13Q1.006.tif NDVI_A2001225_MOD13Q1.006.tif NDVI_A2001241_MOD13Q1.006.tif NDVI_A2001257_MOD13Q1.006.tif NDVI_A2001273_MOD13Q1.006.tif NDVI_A2001289_MOD13Q1.006.tif NDVI_A2001305_MOD13Q1.006.tif NDVI_A2001321_MOD13Q1.006.tif NDVI_A2001337_MOD13Q1.006.tif NDVI_A2001353_MOD13Q1.006.tif -o NDVI_A2001-MOD13Q1.006.tif
gdal_merge = @(iTifs,oTif) ['gdal_merge.py -separate -o ',fullfile(DIR_STACK,oTif),iTifs];

% *** old-one, used as further reference ***
% gdalwarp -of GTiff -t_srs "EPSG:4326" mosaik.vrt mosaik.tif
%% batch conversion

% break-down the list:
Fp      = cell2mat( strfind(LIST,'_') );
if sum( sum(diff(Fp))~=0 )
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

L       = char(LIST);
UL      = unique(cellstr(L(:,Fp(1)+2:Fp(2)-4)));
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

% yearly mosaic requires tiles for each day:
for y=1:numel(YEARS)
    
    % skip the unavailable year:
    if find(YEARS(y)==YEARS(iB))
        fprintf('Year=%d skipped!\n',YEARS(y))
        continue
    end

    % display the current year:
    fprintf('YEAR: %d\n',YEARS(y));
    
    % set current year:
    yLIST = dir( fullfile(DIR_IN, [BAND,'_A',num2str(YEARS(y)),'*_',PRODUCT,'.vrt']) );
    yLIST = {yLIST.name}';
    
    % Available days:
    uaDays = cell(size(yLIST));
    for ii=1:numel(yLIST)
        if ~isempty(strfind(yLIST{ii},['A',num2str( YEARS(y) )]))
            uaDays{ii} = yLIST{ii}(Fp(1)+6:Fp(2)-1);
        else
            uaDays{ii} = '';
        end
    end
    %if isempty(uaDays{1}), uaDays(1)=[]; end

    if viaVRT
        % open file
        fid = fopen(FIL_LIST,'w'); %#ok<UNRCH>
    end
    % loop on all available days in folder and skip those days outside the
    % range SDOY:EDOY
    iTifs = '';
    for d=1:numel(uaDays)
        FILdoy = [BAND,'_A',num2str(YEARS(y)),uaDays{d},'_',PRODUCT];
        vrt = [FILdoy,'.vrt'];
        tif = [FILdoy,'.tif'];
        iTifs = [iTifs,' ',fullfile(DIR_OUT,tif)]; %#ok<AGROW>
        % if available day is outside defined range, skip
        if str2double(uaDays{d})<SDOY || str2double(uaDays{d})>EDOY ...
           || isempty(uaDays{d})
            fprintf('\tDOY=%s skipped! [%s]\n',uaDays{d},yLIST{d})
            continue
        end
        
        fprintf('\tDOY=%s found!  Including... [%s]\n',uaDays{d},yLIST{d})
        % viaVRT=false ==> one tif for each DOY will be delivered:
        if ~viaVRT
            % |03| gdalwarp: convert single images from .vrt to .tif
            %      take single NDVI_A2001001_MOD13Q1.006.vrt
            %      skip or overwrite?
            EXISTS=false;
            if exist(fullfile(DIR_OUT,tif),'file'), EXISTS=true; end
            if OVERWRITE || ~EXISTS
                fprintf('\t\tRunning...\n\t\t\t%s\n',gdalwarp( vrt,tif ))
                [~,reply] = system( gdalwarp( vrt,tif ) );
                fprintf('%s\n',reply)
            elseif EXISTS && ~OVERWRITE
                fprintf('\t\tSkipped because already EXISTS!\n')
            end
        else
            % write in file the list of images to be aggregated in the
            % stack:
            fprintf(fid,'%s\n',fullfile(DIR_IN,yLIST{d}));
        end 
    end
        
    if viaVRT
        fclose(fid); %#ok<UNRCH>
        clear fid;

        % |01| gdalbuildvrt: composition of yearly stack in .vrt
        fprintf('\n\t%s\n','Yearly stack creation:')
        % 'NDVI_A2001_MOD13Q1.006.vrt'
        vrt = [BAND,'_A',num2str(YEARS(y)),'-',PRODUCT,'.vrt'];% I need the "-" to distinguish the stack filename from single image one!
        EXISTS=false;
        if exist(fullfile(DIR_IN,vrt),'file'), EXISTS=true; end
        if OVERWRITE || ~EXISTS
            fprintf('\t\tRunning...\t%s\n', gdalbuildvrt( vrt ) )
            [~,reply] = system( gdalbuildvrt( vrt ) );
            fprintf('\t\t\t%s\n',reply);
        elseif EXISTS && ~OVERWRITE
            fprintf('\t\tSkipped because already EXISTS!  [%s]\n',fullfile(DIR_IN,vrt))
        end
        
        % |02| gdal_translate: convert yearly stack from .vrt to .tif
        if createStack
            tif = [BAND,'_A',num2str(YEARS(y)),'_',PRODUCT,'.tif'];
            EXISTS=false;
            if exist(fullfile(DIR_STACK,tif),'file'), EXISTS=true; end
            if OVERWRITE || ~EXISTS
                fprintf('\t\tRunning...\t%s\n',gdal_translate( vrt,tif ))
                [~,reply] = system( gdal_translate( vrt,tif ) );
                fprintf('\t\t\t%s\n',reply)
            elseif EXISTS && ~OVERWRITE
                fprintf('\t\tSkipped because already EXISTS!  [%s]\n',fullfile(DIR_STACK,tif))
            end
        end
        
        % delete file list .txt:
        delete(FIL_LIST)
    else
        % |04| create a yearly stack of images
        if createStack
            % e.g. 'NDVI_A2001-MOD13Q1.006.tif'
            %fprintf('\t%s\n','The yearly stack creation is de-activated because gdal_merge.py currently does not work!')
            fprintf('\t%s\n','Yearly stack creation:') %#ok<UNRCH>
            oTif = [BAND,'_A',num2str(YEARS(y)),'_',PRODUCT,'.tif'];
            EXISTS=false;
            if exist(fullfile(DIR_STACK,oTif),'file'), EXISTS=true; end
            if OVERWRITE || ~EXISTS
            %if 0% I need to install a working copy of gdal_merge.py before to activate this block
                fprintf( '\t\tRunning...\t%s\n', gdal_merge(iTifs,oTif) )
                [~,reply] = system( gdal_merge(iTifs,oTif) );
                fprintf('\t\t\t%s\n',reply)
                fprintf( 'On error running "gdal_merge.py", run the following command on ftp-pedology as root:\n\t%s\n\n', ...
                         strrep(gdal_merge(iTifs,oTif),'DATI','FTP') )
            elseif EXISTS && ~OVERWRITE
                fprintf('\t\tSkipped because already EXISTS!  [%s]\n',fullfile(DIR_STACK,oTif))
            end
        end
    end
end
