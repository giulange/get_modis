%% DEVELOP THE CODE TO DOWNLOAD SNOW COVER DATA FROM AUTHENTICATED PORTAL
% For few details see the README.wget file.
%% MODIS File Naming Convention
%   Example file name:
%       MYD[PID].A[YYYY][DDD].h[NN]v[NN].[VVV].[yyyy][ddd][hhmmss].hdf
% 
%     MYD           MODIS/Aqua
%     PID           Product ID
%     A             Acquisition date follows
%     YYYY          Acquisition year
%     DDD           Acquisition day of year
%     h[NN]v[NN]	Horizontal tile number and vertical tile number (see Grid for details.)
%     VVV           Version (Collection) number
%     yyyy          Production year
%     ddd           Production day of year
%     hhmmss        Production hour/minute/second in GMT
%     .hdf          HDF-EOS formatted data file
%% wget parameters:
%   -p          This option causes Wget to download all the files that are
%               necessary to properly display a given HTML page.  This
%               includes such things as inlined images, sounds, and
%               referenced stylesheets.
%               extended version is --page-requisites
%   -c          Continue getting a partially-downloaded file.
%   -N          Turn on time-stamping.
%   -r          Turn on recursive retrieving. The default maximum depth is
%               5. 
%   -l depth    Specify recursion maximum depth level depth.
%   -nc         When running Wget with -r or -p, but without -N, -nd, or
%               -nc, re-downloading a file will result in the new copy
%               simply overwriting the old.  Adding -nc will prevent this
%               behavior, instead causing the original version to be
%               preserved and any newer copies on the server to be ignored.
%               extended version is --no-clobber
%   -np         Do not ever ascend to the parent directory when retrieving
%               recursively.  This is a useful option, since it guarantees
%               that only the files below a certain hierarchy will be
%               downloaded.
%               extended version is --no-parent
%   -e command  Execute command.
%   -o logfile  Log all messages to logfile. The messages are normally
%               reported to standard error.
%   -q          Turn off Wget's output.
%               extended version is --quiet
%   -i file     Read URLs from a local or external file.
%               extended version is --input-file=file
%   -nd         Do not create a hierarchy of directories when retrieving
%               recursively.  With this option turned on, all files will
%               get saved to the current directory, without clobbering (if
%               a name shows up more than once, the filenames will get
%               extensions .n).
%               extended version is --no-directories
%   -P prefix   Set directory prefix to prefix.  The directory prefix is
%               the directory where all other files and subdirectories will
%               be saved to, i.e. the top of the retrieval tree.  The
%               default is . (the current directory).
%               extended version is --directory-prefix=prefix
%   -O file     The documents will not be written to the appropriate files,
%               but all will be concatenated together and written to file.
%               extended version is --output-document=file
%% PARs
%% -- FIXED
PORTAL      = 'https://n5eil01u.ecs.nsidc.org';
basic_pars  = '--load-cookies ~/.urs_cookies --save-cookies ~/.urs_cookies --keep-session-cookies --no-check-certificate --auth-no-challenge=on';
%% -- PARAMETRIC
PLATFORM    = 'MOSA';% { MOSA, MOST, ...  }
PRODUCT     = 'MYD10A1.006';% { MYD10A1.006 }
Sdate       = '2003.03.14';% yyyy.mm.dd % { 2002.07.04 , ... }
Edate       = '2003.03.15';% yyyy.mm.dd % { 2017.01.01 , ... }
TILES       = {'h18v04','h18v05','h19v04','h19v05'};
DIR_OUT     = '/media/DATI/db-backup/MODIS/hdf-it/snowcover';
FIL_FORMAT  = '.hdf';
WITH_XML    = false;
OVERWRITE   = false;
%% ORIGINAL COMMANDS (fnc handles to...)
wget_tile   = @(link,oDir) ['wget ',basic_pars,' -r -nd --reject "index.html*" -np -e robots=off -P ',oDir, ' ',link];
% rm          = @(dir_del) ['rm -vrf ',dir_del];
%% RETRIEVE list of SATELLITES:
satlist     = nsidc_get_satlist;
%% RETRIEVE list of PRODUCTS:
prodlist    = nsidc_get_prodlist( satlist{3} );
%% RETRIEVE list of DATES:
dateslist   = nsidc_get_dateslist( prodlist{4}, PLATFORM );
%% main
SD          = datenum( Sdate, 'yyyy.mm.dd' );
ED          = datenum( Edate, 'yyyy.mm.dd' );
AD          = datenum( dateslist, 'yyyy.mm.dd' );
fSD         = find(AD==SD);
fED         = find(AD==ED);
% CHECK DATES:
%   Start:
if isempty(fSD), error('Start date not found at %s.',[PORTAL,'/',PLATFORM,'/',PRODUCT]), end
%   End:
if isempty(fED), error(  'End date not found at %s.',[PORTAL,'/',PLATFORM,'/',PRODUCT]), end
%   Duplicates:
if numel(fSD)>1 || numel(fED)>1
    error('Duplicated dates for platform:%s and product:%s',PLATFORM,PRODUCT)
end
%   Missing dates at PORTAL/PLATFORM/PRODUCT location:
Fdad = find(diff(AD)>1);
MISSING_DATES_ON_SERVER = cell( numel(Fdad), 1 );
for ii = 1:numel(Fdad)
    Fnum = datenum( dateslist(Fdad(ii):Fdad(ii)+1), 'yyyy.mm.dd' );
    MISSING_DATES_ON_SERVER{ii} = datestr( Fnum(1)+1:Fnum(2)-1 );
end

for tt = fSD:fED
    % RETRIEVE list of TILES:
    tileslist = nsidc_get_tileslist( dateslist{tt}, prodlist{4}, PLATFORM );
    
    % DOWNLOAD the required TILES:
    F1      = strfind(tileslist,FIL_FORMAT);
    D       = false(size(tileslist));
    for jj = 1:numel(TILES)
        F2  = strfind(tileslist,TILES{jj});
        F3  = strfind(tileslist,'.xml');

        %intersect(F1,F2);
        for ii = 1:numel(tileslist)
            if isempty(F1{ii}) || isempty(F2{ii})
                continue
            elseif ~WITH_XML && ~isempty(F3{ii})
                continue
            end
            D(ii) = true;
        end
    end
    if ~sum(D)
        warning( 'Current DOY=%s is not available on the server!', dateslist{tt} )
        continue
    end
    D       = tileslist(D);
    for dd = 1:numel(D)
        reply   = '';
        Fexists = false;
        if exist( fullfile(DIR_OUT,D{dd}), 'file' ), Fexists=true; end
        if OVERWRITE
            if Fexists
                fprintf( 'Overwriting tile %s...\n',D{dd} )
                delete( fullfile(DIR_OUT,D{dd}) )
            else
                fprintf( 'Downloading tile %s...\n',D{dd} )
            end
            url = [PORTAL,'/',PLATFORM,'/',PRODUCT,'/',dateslist{tt},'/',D{dd}];
            [status,reply] = system(  wget_tile( url, DIR_OUT )  );
            if status, error('%s',reply), end
        else
            if Fexists
                fprintf( 'Skipping tile %s...\n',D{dd} )
            else
                fprintf( 'Downloading tile %s...\n',D{dd} )
                url = [PORTAL,'/',PLATFORM,'/',PRODUCT,'/',dateslist{tt},'/',D{dd}];
                [status,reply] = system(  wget_tile( url, DIR_OUT )  ); 
                if status, error('%s',reply), end 
            end
        end
    end
end