function varargout = pf_dax_math_v1(action,varargin)
%PF_DAX_MATH_V1 Pure removal, aggregation and paired-summary calculations.

switch lower(string(action))
    case "drawmeans"
        varargout{1} = local_drawmeans(varargin{:});
    case "quantile"
        varargout{1} = ppu_math_v1('quantile',varargin{:});
    case "summaries"
        [varargout{1:nargout}] = local_summaries(varargin{:});
    otherwise
        error('JWPE:PFDAX:Math','Unsupported PF DAX math action.');
end
end

function means = local_drawmeans(cout,cin,phase)
assert(isnumeric(cout) && isnumeric(cin) && size(cout,2)==numel(cin) && ...
    all(isfinite(cout),'all') && all(isfinite(cin)) && all(cin>0), ...
    'JWPE:PFDAX:Removal','Invalid removal inputs.');
cin = double(cin(:).');
removal = 100*(cin-double(cout))./cin;
means = [mean(removal(:,phase.phaseI),2), ...
    mean(removal(:,phase.phaseII),2), ...
    mean(removal(:,phase.phaseIII),2),mean(removal,2)];
assert(all(isfinite(means),'all'),'JWPE:PFDAX:Removal', ...
    'Removal means must be finite and are never clipped.');
end

function [summary,paired] = local_summaries(means,cfg)
assert(isequal(size(means),[cfg.logicalPairs 4]) && ...
    all(isfinite(means),'all'),'JWPE:PFDAX:Summary', ...
    'Draw-level means are incomplete.');
cube = reshape(means,[cfg.selectedRows,numel(cfg.f),4]);
baseline = cube(:,cfg.baselineIndex,:);
delta = cube-baseline;
paired = reshape(delta,[cfg.logicalPairs,4]);
n = numel(cfg.f)*4;
coordinateID = zeros(n,1); multiplier = zeros(n,1); setName = strings(n,1);
removalQ025 = zeros(n,1); removalMedian = zeros(n,1); removalQ975 = zeros(n,1);
deltaQ025 = zeros(n,1); deltaMedian = zeros(n,1); deltaQ975 = zeros(n,1);
sets = ["PHASE_I" "PHASE_II" "PHASE_III" "OVERALL"];
cursor = 0;
for c = 1:numel(cfg.f)
    for s = 1:4
        cursor = cursor+1;
        q = ppu_math_v1('quantile',cube(:,c,s),cfg.quantiles);
        qd = ppu_math_v1('quantile',delta(:,c,s),cfg.quantiles);
        coordinateID(cursor) = c; multiplier(cursor) = cfg.f(c);
        setName(cursor) = sets(s);
        removalQ025(cursor) = q(1); removalMedian(cursor) = q(2);
        removalQ975(cursor) = q(3); deltaQ025(cursor) = qd(1);
        deltaMedian(cursor) = qd(2); deltaQ975(cursor) = qd(3);
    end
end
summary = table(coordinateID,multiplier,setName,removalQ025, ...
    removalMedian,removalQ975,deltaQ025,deltaMedian,deltaQ975, ...
    'VariableNames',{'CoordinateID','Multiplier','Set','RemovalQ025', ...
    'RemovalMedian','RemovalQ975','PairedDeltaQ025','PairedDeltaMedian', ...
    'PairedDeltaQ975'});
baseRows = summary.CoordinateID==cfg.baselineIndex;
assert(all(summary{baseRows,7:9}==0,'all'),'JWPE:PFDAX:Summary', ...
    'Paired baseline changes must be exactly zero.');
end
