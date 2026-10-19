function s = g2_metric(reactor,N,X,Y,cfg,parameterNames)
%G2_METRIC Compute signed SRRC and phase-balanced summaries at 18 times.

reactor = upper(string(reactor));
X = double(X);
Y = double(Y);
assert(isequal(size(X),[N 6]) && isequal(size(Y),[N 18]), ...
    'JWPE:G2:Dimension','SRRC input dimensions are invalid.');
assert(all(isfinite(X),'all') && all(isfinite(Y),'all'), ...
    'JWPE:G2:Dimension','SRRC inputs must be finite.');
assert(isequal(cfg.times.all_d,5:5:90),'JWPE:G2:OutputTimes', ...
    'Corrected output-time grid changed.');
if nargin<6
    parameterNames = cfg.names.sample;
end

RX = zeros(size(X));
for j=1:6
    RX(:,j) = local_rank(X(:,j));
end
ZX = local_standardize(RX);
assert(rank(ZX)==6,'JWPE:G2:Metric','Ranked input design is rank deficient.');
coef = nan(18,6);
r2 = nan(18,1);
for t=1:18
    zy = local_standardize(local_rank(Y(:,t)));
    beta = ZX\zy;
    fitted = ZX*beta;
    coef(t,:) = beta(:).';
    sse = sum((zy-fitted).^2);
    sst = sum((zy-mean(zy)).^2);
    assert(sst>0,'JWPE:G2:Metric','Ranked output is constant at day %.12g.', ...
        cfg.times.all_d(t));
    r2(t) = max(0,min(1,1-sse/sst));
end
iI = cfg.times.phaseLabel=="I";
iII = cfg.times.phaseLabel=="II";
M_I = mean(abs(coef(iI,:)),1);
M_II = mean(abs(coef(iII,:)),1);
M_BAL = (M_I+M_II)/2;
phaseR2 = [mean(r2(iI)),mean(r2(iII))];
[maxI,timeI,signI,valueI] = local_maxima(coef(iI,:),cfg.times.phaseI_d);
[maxII,timeII,signII,valueII] = local_maxima(coef(iII,:),cfg.times.phaseII_d);
s = struct('reactor',char(reactor),'N',N,'parameterNames',parameterNames, ...
    'times_d',cfg.times.all_d,'phaseLabel',cfg.times.phaseLabel, ...
    'srrc',coef,'r2Time',r2,'M_I',M_I,'M_II',M_II,'M_BAL',M_BAL, ...
    'phaseR2',phaseR2,'timeR2PassCount',nnz(r2>=cfg.metric.r2Threshold), ...
    'r2Gate',all(phaseR2>=cfg.metric.r2Threshold) && ...
    nnz(r2>=cfg.metric.r2Threshold)>=cfg.metric.minPassingTimes, ...
    'maxima',struct('I',struct('abs',maxI,'time_d',timeI,'sign',signI, ...
    'signed',valueI),'II',struct('abs',maxII,'time_d',timeII,'sign',signII, ...
    'signed',valueII)));
end

function r = local_rank(x)
x = double(x(:));
n = numel(x);
[sorted,order] = sort(x,'ascend');
rankSorted = zeros(n,1);
i = 1;
while i<=n
    j = i;
    while j<n && sorted(j+1)==sorted(i)
        j = j+1;
    end
    rankSorted(i:j) = (i+j)/2;
    i = j+1;
end
r = zeros(n,1);
r(order) = rankSorted;
end

function z = local_standardize(x)
sigma = std(x,0,1);
assert(all(sigma>0),'JWPE:G2:Metric','Ranked variable has zero variance.');
z = (x-mean(x,1))./sigma;
end

function [maxAbs,maxTime,maxSign,signedValue] = local_maxima(C,times)
[maxAbs,idx] = max(abs(C),[],1);
maxTime = times(idx);
signedValue = zeros(1,size(C,2));
for j=1:size(C,2)
    signedValue(j) = C(idx(j),j);
end
maxSign = sign(signedValue);
end
