function M = phenologicalmetrics(vifilt,viraw)
% M = phenologicalmetrics(vifilt,viraw)
% 
% INPUTS
%   vifilt    : Vegetation index (e.g. NDVI) after filtering using whatever
%               model (ARMA, harmonic regression, Savitzky Golay filter,
%               etc.).
%   viraw     : Raw vegetation index values as reported in the MODIS grids.
% 
% OUTPUTS
%   M         : Structure array with all phenological metrics as reported
%               below.
% 
% DESCRIPTION
%   This function computes the phenological metrics as reported in the
%   paper:
%       Bradley et al., "Measuring phenological variability from satellite
%       imagery", Journal of Vegetation Science, 5: 703-714, 1994.
%   _______________________________________________________________________
%      Metric                         Phenological interpretation
%   _______________________________________________________________________
%      
%      Temporal NDVI metrics
%      Time of onset of greenness     Beginning of measureable photosynthesis
%      Time of end of greenness       Cessation of measureable photosynthesis
%      Duration of greenness          Duration of photosynthetic activity
%      Time of maximum NDVI           Time of maximum measureable photosynthesis
% 
%      NDVI-value metrics
%      Value of onset of greenness    Level of photosynthetic activity at beginning of growing season
%      Value of end of greenness      Level of photosynthetic activity at end of growing season
%      Value of maximum NDVI          Maximum measureable level of photosynthetic activity
%      Range of NDVI                  Range of measureable photosynthetic activity
% 
%      Derived metrics
%      Time-integrated NDVI           Net primary production
%      Rate of greenup                Acceleration of photosynthesis
%      Rate of senescence             Deceleration of photosynthesis
%      Modality                       Periodicity of photosynthetic activity
%   _______________________________________________________________________

%% PRE
n = numel(vifilt);
isShifted=false;
x0=num2str((1:n)');
%% main
% onset of greenness:
deltas   = diff(vifilt);
[~,OnP]  = max( deltas );
[~,fMin] = sort( deltas );
% End of scenescence:
EndP = fMin(1);% take the lowest difference, which should be negative!
EndP = min(n,EndP+1);% diff caused a -1 on EndP => +1, but don't go beyond n!
EndV = vifilt(EndP);
if EndP<OnP % the greenness belongs to two years!
    isShifted=true;
    % circshift the time-series only to calculte metrics
    [~,Fmn]=min(vifilt);
    vifilt = circshift(vifilt, n-Fmn+1);
    viraw  = circshift(viraw,  n-Fmn+1);
    x0     = circshift(x0,     n-Fmn+1);
    % Re-compute the greenness extremes:
    % onset of greenness:
    deltas   = diff(vifilt);
    [~,OnP]  = max( deltas );
    [~,fMin] = sort( deltas );
    % end of greenness:
    EndP=fMin(1);
    EndV=vifilt(EndP);
end
OnV = vifilt(OnP);
% Other phenological pars:
[MaxV,MaxP] = max(vifilt);
DurP = EndP-OnP;
RanV = MaxV - min([OnV,EndV]);
RtUp = (MaxV-OnV ) / (MaxP - OnP );
RtDn = (MaxV-EndV) / (EndP - MaxP);

% TINDVI = trapz(VI(OnP:EndP));
yv = [vifilt(OnP:EndP);vifilt(OnP)];
xv = [1:(EndP-OnP)+1,1]';
TINDVI = polyarea(xv,yv);
% figure,plot(xv,yv)

figure(8),clf,whitebg('k')
plot( viraw, '--g' ), hold on
plot( vifilt , '-w', 'lineWidth',3 );
set(gca,'Xtick',1:n)
set(gca,'XtickLabel',cellstr(x0)')
scatter( OnP, OnV, 'sr', 'filled' )
scatter( EndP,EndV,'sr', 'filled' )
scatter( MaxP,MaxV,'sr', 'filled' )
text(n+1,OnV, 'OnV','FontSize',8)
text(n+1,EndV,'EndV','FontSize',8)
text(n+1,MaxV,'MaxV','FontSize',8)
text(OnP,1, 'OnP','FontSize',8)
text(EndP,1, 'EndP','FontSize',8)
text(MaxP,1, 'MaxP','FontSize',8)
line([OnP,MaxP],[OnV,MaxV],'LineStyle','-','Color','r')%   RtUp
line([MaxP,EndP],[MaxV,EndV],'LineStyle','-','Color','r')% RtDn
text(mean([OnP,MaxP]),mean([OnV,MaxV]), 'RtUp','FontSize',10, 'HorizontalAlignment','left','VerticalAlignment','top','Color','r')
text(mean([MaxP,EndP]),mean([MaxV,EndV]), 'RtDn','FontSize',10, 'HorizontalAlignment','right','VerticalAlignment','top','Color','r')
% lines to define location of labels on filtered line
%   -vertical lines
line([OnP,OnP],[1,OnV],'LineStyle',':','Color','y')
line([MaxP,MaxP],[1,MaxV],'LineStyle',':','Color','y')
line([EndP,EndP],[1,EndV],'LineStyle',':','Color','y')
%   -horizontal lines
line([OnP,n+1],[OnV,OnV],'LineStyle',':','Color','y')
line([MaxP,n+1],[MaxV,MaxV],'LineStyle',':','Color','y')
line([EndP,n+1],[EndV,EndV],'LineStyle',':','Color','y')
hold off
xlabel('\fontsize{12}\color{black}\bf Time [16-days]')
ylabel('\fontsize{12}\color{magenta}\bf NDVI - MODIS')

if isShifted
    OnP = OnP-(n-Fmn+1); if OnP<1, OnP=n+OnP; end
    EndP=EndP-(n-Fmn+1); if EndP<1, EndP=n+EndP; end
    MaxP=MaxP-(n-Fmn+1); if MaxP<1, MaxP=n+MaxP; end
end
M.OnP = OnP;
M.OnV = OnV;
M.EndP = EndP;
M.EndV = EndV;
M.MaxP = MaxP;
M.MaxV = MaxV;
M.DurP = DurP;
M.RanV = RanV;
M.RtUp = RtUp;
M.RtDn = RtDn;
M.TINDVI = TINDVI;

%% return
end