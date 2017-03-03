function S = visignaldecomposition( ts, period, plotme )
% 
% 
% INPUTS
% 
% OUTPUTS
% 
% 
% DESCRIPTION

%% PRE
if nargin<3
    plotme=false;
end
x0  = (1:numel(ts))';
%% ------ [√]Discrete-time stochastic process

%% ------ [√]mu    [mean / long trend component]
% LONG TREND COMPONENT
%   global mean:
mu  = nanmean( ts );
%   running mean:
% % wghts = [.5,ones(1,numel(DOY_LIST)-1),.5]/numel(DOY_LIST);
% % % wghts = fspecial('gaussian',[1,numel(DOY_LIST)-1]);
% % % wghts = [wghts(1:numel(wghts)/2),0,wghts(numel(wghts)/2+1:end)];
% % sum(wghts)
% % Yt(NA)=mean(Yt);
% % mu = filter(wghts, 1, tmp);

% DETRENDED
Ymu = ts-mu;

if plotme
    % figure
    figure(10), hold on
    plot(x0,Ymu,'color',[0.6,0.6,0.6])
    % figure(1),clf,
    line([x0(1),x0(end)],[mu,mu]), datetick('x','mmm-yy'), 
    xlabel('Time (days)','fontsize',12), ylabel('\mu_t', 'fontsize',15),
    title('Long Trend Component','fontsize',15,'fontweight','b')
    hold off
end
%% ------ [√]psi   [harmonic regression / seasonality]
% Harmonic Regression (i.e. an OLS regression using sin and cos waves)
tau = period;           % PERIOD
f = 1/tau;              % FERQUENCY
t = (1:length(x0))';    % TIME
% OLS regression [without intercept, since mu is already an intercept!!]
X   = [cos(2*pi*f*t),sin(2*pi*f*t)];
ab  = regress(Ymu(t),X);
A   = ab(1);
B   = ab(2);
psi = A*cos(2*pi*f*t) + B*sin(2*pi*f*t);
% DESEASONALIZED
Ymupsi = Ymu-psi;

if plotme
    % figure
    figure(10), hold on
    plot(x0,Ymupsi,'color',[0.6,0.3,0.6])
    % figure(2),clf,plot(x0(1:round(tau)), psi(1:round(tau)),'color',[0.8,0.8,0.8],'linewidth',2),
    plot(x0, psi,'color',[0.8,0.8,0.8],'linewidth',2),
    % datetick('x','dd'), xlabel('Month','fontsize',12),
    ylabel('\psi_t', 'fontsize',15),
    % title('Seasonality','fontsize',15,'fontweight','b')
    hold off
end
%% signal composition
S = mu + psi;
%% exit
end