function out = mc_diag_v1(chains,cfg,label)
%MC_DIAG_V1 Rank-normalized split Rhat and bulk/tail ESS (Vehtari 2021).

if nargin<3, label = 'INFERENCE'; end
assert(iscell(chains) && numel(chains)==4,'JWPE:MC:Diagnostics', ...
    'Exactly four chains are required.');
n = size(chains{1},1);
assert(n>=4,'JWPE:MC:Diagnostics','Chains are too short to split.');
for c=1:4
    assert(isequal(size(chains{c}),[n,7]) && ...
        all(isfinite(chains{c}),'all'),'JWPE:MC:Diagnostics', ...
        'Chains must have equal finite dimensions.');
    chains{c}(:,6:7) = exp(chains{c}(:,6:7));
end
Rhat = nan(7,1); BulkESS = nan(7,1); TailESS = nan(7,1);
for parameterIndex=1:7
    x = cellfun(@(z)z(:,parameterIndex),chains,'UniformOutput',false);
    split = local_split(x);
    pooled = split(:); z = local_rank_normalize(pooled);
    z = reshape(z,size(split));
    folded = abs(pooled-median(pooled));
    zFold = reshape(local_rank_normalize(folded),size(split));
    Rhat(parameterIndex) = max(local_rhat(z),local_rhat(zFold));
    BulkESS(parameterIndex) = local_ess(z);
    q05 = local_quantile(pooled,cfg.diagnostics.tailProbability);
    q95 = local_quantile(pooled,1-cfg.diagnostics.tailProbability);
    low = double(split<=q05); high = double(split>=q95);
    TailESS(parameterIndex) = min(local_ess(low),local_ess(high));
end
Pass = Rhat<cfg.diagnostics.rhatMaximum & ...
    BulkESS>cfg.diagnostics.bulkESSMinimum & ...
    TailESS>cfg.diagnostics.tailESSMinimum;
Parameter = cfg.reportNames(:);
Label = repmat(string(label),7,1);
out.table = table(Parameter,Rhat,BulkESS,TailESS,Pass,Label);
out.pass = all(Pass);
out.version = cfg.diagnostics.version;
out.chainLength = n;
out.splitChainLength = floor(n/2);
out.label = char(label);
end

function x = local_split(chains)
n = floor(numel(chains{1})/2); m = numel(chains);
x = zeros(n,2*m);
for c=1:m
    values = chains{c};
    x(:,2*c-1) = values(1:n);
    x(:,2*c) = values(end-n+1:end);
end
end

function z = local_rank_normalize(x)
r = local_tied_rank(x);
p = (r-3/8)/(numel(x)+1/4);
z = -sqrt(2)*erfcinv(2*p);
end

function r = local_tied_rank(x)
[sorted,order] = sort(x(:)); n = numel(sorted); ranks = zeros(n,1);
first = 1;
while first<=n
    last = first;
    while last<n && sorted(last+1)==sorted(first), last = last+1; end
    ranks(first:last) = (first+last)/2;
    first = last+1;
end
r = zeros(n,1); r(order) = ranks;
end

function value = local_rhat(x)
n = size(x,1); chainMeans = mean(x,1); W = mean(var(x,0,1));
if W<=0 || ~isfinite(W), value = Inf; return, end
B = n*var(chainMeans,0,2);
varPlus = (n-1)/n*W+B/n;
value = sqrt(varPlus/W);
end

function ess = local_ess(x)
[n,m] = size(x); chainMeans = mean(x,1); chainVar = var(x,0,1);
W = mean(chainVar); B = n*var(chainMeans,0,2);
varPlus = (n-1)/n*W+B/n;
if ~(varPlus>0) || ~isfinite(varPlus), ess = 0; return, end
rho = zeros(n,1); rho(1) = 1;
for lag=1:n-1
    acov = zeros(m,1);
    for chainIndex=1:m
        centered = x(:,chainIndex)-chainMeans(chainIndex);
        acov(chainIndex) = sum(centered(1:n-lag).* ...
            centered(1+lag:n))/n;
    end
    rho(lag+1) = 1-(W-mean(acov))/varPlus;
end
pairs = zeros(ceil(n/2),1); pairCount = 0;
for first=1:2:n-1
    pair = rho(first)+rho(first+1);
    if pair<0, break, end
    pairCount = pairCount+1;
    if pairCount>1, pair = min(pair,pairs(pairCount-1)); end
    pairs(pairCount) = pair;
end
if pairCount==0
    tau = 1;
else
    tau = max(1,-1+2*sum(pairs(1:pairCount)));
end
sampleCount = n*m;
ess = min(sampleCount/tau,sampleCount*log10(sampleCount));
end

function q = local_quantile(x,p)
x = sort(x(:)); h = (numel(x)-1)*p+1; lo = floor(h); hi = ceil(h);
if lo==hi
    q = x(lo);
else
    q = x(lo)+(h-lo)*(x(hi)-x(lo));
end
end
