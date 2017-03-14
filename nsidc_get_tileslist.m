function list = nsidc_get_tileslist(date,product,platform,url)
% list = nsidc_get_tileslist(date,product,platform,url)
% 
% DESCRIPTION
%   This function is able to retrive the list of all available tiles for
%   the given date (e.g. 2002.07.05), product (e.g. MYD10A1.006) and
%   platform (e.g. MOSA) at the https://n5eil01u.ecs.nsidc.org portal,
%   which is used as default in case the input url is not provided.
% 
% INPUTS
%   date        Date with format YYYY.MM.DD within which retrieve the full
%               list of tiles. For a complete list of available dates run
%               the nsidc_get_dateslist.m function beforehand.
%   product     One product (such as MYD10A1.006) from which download
%               satellites data. For a complete list of available products
%               run the nsidc_get_prodlist.m function beforehand.
%   platform    One platform from the list available at (pre)defined url.
%               If you need to know the list of available platforms run the
%               nsidc_get_satlist.m beforehand.
%   url         The Data Pool at the NSIDC Distributed Active Archive
%               Center (DAAC). The Data Pool allows users to download
%               select NSIDC Earth Observing System (EOS) data directly via
%               HTTPS.
%               default :: https://n5eil01u.ecs.nsidc.org
% 
% OUTPUTS
%   list        Provides the list of all tiles under the combined
%               product/platform available under the pre(defined) url.

%% CHECK INPUTS
if nargin <4
    url = 'https://n5eil01u.ecs.nsidc.org';
else
    warning('You are changing the reference URL from which to retrieve the list of platforms.')
end
%% PARs
basic_pars  = '--load-cookies ~/.urs_cookies --save-cookies ~/.urs_cookies --keep-session-cookies --no-check-certificate --auth-no-challenge=on';
DIR_TMP     = '~/.tmpdir';
%% fnc handles
rm          = @(dir_del) ['rm -vrf ',dir_del];
wget_index  = @(link,oDir) ['wget ',basic_pars,' -c -np -e robots=off -P ',oDir, ' ',link];
%% main
% download available satellites:
[status,reply] = system(  wget_index( [url,'/',platform,'/',product,'/',date], DIR_TMP )  );
if status, error('%s',reply), end
html = greadtext( fullfile(DIR_TMP,date) );
if size(html,2)>1
    warning('The html cell array has more than one column, only the first one is retained!')
    html = html(:,1);
end

FDIR = nan(numel(html),1);
for ii = 1:numel(html)
    if isempty( html{ii} )
        FDIR(ii) = 0;
    else
        if isempty(strfind(html{ii},'[   ]')) && isempty(strfind(html{ii},'[IMG]'))
            FDIR(ii) = 0;
        else
            if ~isempty(strfind(html{ii},'[   ]'))
                FDIR(ii) = strfind(html{ii},'[   ]');
            else
                FDIR(ii) = strfind(html{ii},'[IMG]');
            end
        end
    end
end
Fhref = nan(numel(html),1);
for ii = 1:numel(html)
    if FDIR(ii)==0
        Fhref(ii,1) = 0;
    else
        if isempty(strfind(html{ii},'<a href="'))
            Fhref(ii,1) = 0;
        else
            tmp = strfind(html{ii},'<a href="');
            if sum(tmp>FDIR(ii))>1
                error('check the html code! changes in the original code were detected')
            end
            Fhref(ii,1) = tmp( tmp>FDIR(ii) );
        end
    end
end
Fdir = nan(numel(html),2);
for ii = 1:numel(html)
    if Fhref(ii,1)==0
        Fdir(ii,1:2) = 0;
    else
        if isempty(strfind(html{ii},'">'))
            Fdir(ii,1:2) = 0;
        else
            
            tmp = strfind(html{ii},'</a></td>');
            if sum(tmp>Fhref(ii))>1
                error('check the html code! changes in the original code were detected')
            end
            Fdir(ii,2) = tmp( tmp>Fhref(ii) )   -1;

            tmp = strfind(html{ii},'">');
            Ftmp = tmp<Fdir(ii,2) & tmp>Fhref(ii,1);
            if sum( Ftmp )>1
                error('check the html code! changes in the original code were detected')
            end
            Fdir(ii,1) = tmp( Ftmp )            +2;
                                    
        end
    end
end
LIST_DATES = cell( sum((Fdir(:,1)>0)), 1 );
iCount = 0;
for ii = 1:numel(html)
    if Fdir(ii,1)==0
        continue
    else
        iCount = iCount+1;
        LIST_DATES{iCount} = html{ii}(Fdir(ii,1):Fdir(ii,2));
    end
end
list = LIST_DATES;
%% DELETE TEMPORARY ITEMS
[status,reply] = system(  rm(DIR_TMP)  );
if status
    error('%s',reply)
else
    fprintf('Following temporary items were removed:\n%s',reply)
end
%% return
end