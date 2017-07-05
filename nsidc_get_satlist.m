function list = nsidc_get_satlist( url )
% list = nsidc_get_satlist( url )
% 
% DESCRIPTION
%   This function is able to retrive the list of Satellites/Platforms
%   available for download from the https://n5eil01u.ecs.nsidc.org portal,
%   which is used as default in case the input url is not provided.
% 
% INPUTS
%   url         The Data Pool at the NSIDC Distributed Active Archive
%               Center (DAAC). The Data Pool allows users to download
%               select NSIDC Earth Observing System (EOS) data directly via
%               HTTPS.
%               default :: https://n5eil01u.ecs.nsidc.org
% 
% OUTPUTS
%   list        Provide the list of all satellites/platforms available at
%               the (pre)defined url.

%% CHECK INPUTS
if nargin <1
    url = 'https://n5eil01u.ecs.nsidc.org';
else
    warning('You are changing the reference URL from which to retrieve the list of satellites')
end
%% PARs
basic_pars  = '--load-cookies ~/.urs_cookies --save-cookies ~/.urs_cookies --keep-session-cookies --no-check-certificate --auth-no-challenge=on';
DIR_TMP     = '~/.tmpdir';
%% fnc handles
rm          = @(dir_del) ['rm -vrf ',dir_del];
wget_index  = @(link,oDir) ['wget ',basic_pars,' -c -np -e robots=off -P ',oDir, ' ',link];
%% main
% download available satellites:
[status,reply] = system(  wget_index( url, DIR_TMP )  );
if status, error('%s',reply), end
html = greadtext( fullfile(DIR_TMP,'index.html') );
if size(html,2)>1
    warning('The html cell array has more than one column, only the first one is retained!')
    html = html(:,1);
end

Fhref = nan(numel(html),1);
for ii = 1:numel(html)
    if isempty( html{ii} )
        Fhref(ii) = 0;
    else
        if isempty(strfind(html{ii},'HREF'))
            Fhref(ii) = 0;
        else
            Fhref(ii) = strfind(html{ii},'HREF');
        end
    end
end
Fvirg = nan(numel(html),2);
for ii = 1:numel(html)
    if Fhref(ii)==0
        Fvirg(ii,1:2) = 0;
    else
        if isempty(strfind(html{ii},'"'))
            Fvirg(ii,1:2) = 0;
        else
            Fvirg(ii,1:2) = strfind(html{ii},'"');
        end
    end
end
Fdir = nan(numel(html),2);
for ii = 1:numel(html)
    if Fvirg(ii,1)==0
        Fdir(ii,1:2) = 0;
    else
        if isempty(strfind(html{ii},'"> /'))
            Fdir(ii,1:2) = 0;
        else
            Fdir(ii,1) = strfind(html{ii},'"> /')      +4;
            Fdir(ii,2) = strfind(html{ii},' </A><P>')  -1;
        end
    end
end
LIST_SAT = cell( sum((Fdir(:,1)>0)), 1 );
iCount = 0;
for ii = 1:numel(html)
    if Fdir(ii,1)==0
        continue
    else
        iCount = iCount+1;
        LIST_SAT{iCount} = html{ii}(Fdir(ii,1):Fdir(ii,2));
    end
end
list = LIST_SAT;
%% DELETE TEMPORARY ITEMS
[status,reply] = system(  rm(DIR_TMP)  );
if status
    error('%s',reply)
else
%     fprintf('Following temporary items were removed:\n%s',reply)
end
%% return
end
