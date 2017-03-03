% This script downloads MODIS files automatically
% See this link as reference:
%   https://jgomezdans.github.io/downloading-modis-data-with-python.html 

%% PARs
%% -- NON-PARAMETRIC
PLATFORM    = 'MOLT'; % type: MOLA, MOLT or MOTA
PRODUCT     = 'MOD13Q1.006';
DIR_OUT     = '/media/DATI/db-backup/MODIS/hdf-it/';
SDOY        = 1;
EDOY        = 366;
USER        = 'giulange';
PSWD        = 'XMa-q9t-pTt-dZC';
%% -- PARAMETRIC
YEARS       = 2016; %2001:2017;
TILES       = {'h18v04','h18v05','h19v04','h19v05'};
%% original command
% !./get_modis.py -v -s MOLT -p MOD13Q1.006 -y 2004 -t h18v04 -o ~/Downloads/modis#2/ -b 1 -e 366
getmodis = @(y,t) ['!~/git/get_modis/./get_modis.py -u ',USER,' -P ',PSWD,' -v -s ',PLATFORM,' -p ',PRODUCT,' -y ',num2str(y),' -t ',t,' -o ',DIR_OUT,' -b ',num2str(SDOY),' -e ',num2str(EDOY)];
%% batch download

for y=1:numel(YEARS)
    for t=1:numel(TILES)
        fprintf( '%s\n', getmodis(YEARS(y),TILES{t}) )
        eval( getmodis(YEARS(y),TILES{t}) )
    end
end