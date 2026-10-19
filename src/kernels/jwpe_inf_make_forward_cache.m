function [simulate,getStats,clearCache] = jwpe_inf_make_forward_cache(rawSimulator,maxEntries)
%JWPE_INF_MAKE_FORWARD_CACHE Exact cache for mechanistic forward simulations.
%
% Cache key = exact six-element native mean parameter vector.
% Observation-error parameters are intentionally absent from the key because
% they do not change the physical state equations or model prediction.
%
% SCIENTIFIC SAFETY
%   A cache miss always calls the validated raw simulator.

if nargin<2 || isempty(maxEntries); maxEntries = 128; end
assert(isa(rawSimulator,'function_handle'),'rawSimulator must be a function handle.');
assert(isscalar(maxEntries) && maxEntries>=1 && maxEntries==floor(maxEntries), ...
    'maxEntries must be a positive integer.');

% Fixed-capacity storage avoids repeated dynamic allocation during long PL/MCMC
% preparation runs. nEntries tracks the active prefix.
cacheTheta = nan(maxEntries,6);
cacheResult = cell(maxEntries,1);
nEntries = 0;
requests = 0; hits = 0; misses = 0; evictions = 0;

simulate = @local_simulate;
getStats = @local_stats;
clearCache = @local_clear;

    function sim = local_simulate(theta)
        theta = theta(:).';
        assert(numel(theta)==6,'Expected six native mean parameters.');
        requests = requests + 1;
        idx = 0;
        for j = nEntries:-1:1
            if isequal(theta,cacheTheta(j,:))
                idx = j;
                break
            end
        end
        if idx>0
            hits = hits + 1;
            sim = cacheResult{idx};
            return
        end

        misses = misses + 1;
        sim = rawSimulator(theta);
        if nEntries < maxEntries
            nEntries = nEntries + 1;
        else
            cacheTheta(1:maxEntries-1,:) = cacheTheta(2:maxEntries,:);
            cacheResult(1:maxEntries-1) = cacheResult(2:maxEntries);
            evictions = evictions + 1;
        end
        cacheTheta(nEntries,:) = theta;
        cacheResult{nEntries} = sim;
    end

    function s = local_stats()
        s = struct('requests',requests,'hits',hits,'misses',misses, ...
            'evictions',evictions,'entries',nEntries,'maxEntries',maxEntries);
        if requests>0; s.hitFraction = hits/requests; else; s.hitFraction = NaN; end
    end

    function local_clear()
        cacheTheta(:) = NaN;
        cacheResult(:) = {[]};
        nEntries = 0;
        requests = 0; hits = 0; misses = 0; evictions = 0;
    end
end
