function [simulateCached,getStats,clearCache] = JWPE_OEM_make_cached_simulator_v1_3(rawSimulator,maxEntries)
%JWPE_OEM_MAKE_CACHED_SIMULATOR_V1_3 Exact mean-parameter forward cache.
%
% The observation likelihood contains parameters (sigmaA/sigmaP) that do not
% change the mechanistic forward prediction. fmincon finite differences can
% therefore request the same six mean parameters multiple times while only
% perturbing observation-error coordinates. This factory reuses an already
% computed canonical forward result when the six native mean parameters are
% bit-for-bit identical.
%
% IMPORTANT
%   * No tolerance-based approximation is used.
%   * No interpolation is used.
%   * Cache misses call the unmodified validated CS/PF forward engine.
%   * Independent final quality rechecks must call the raw simulator, not
%     this cache.

if nargin < 2 || isempty(maxEntries)
    maxEntries = 64;
end
assert(isa(rawSimulator,'function_handle'),'rawSimulator must be a function handle.');
assert(isscalar(maxEntries) && maxEntries>=1 && maxEntries==floor(maxEntries), ...
    'maxEntries must be a positive integer.');

cacheTheta = zeros(0,6);
cacheResult = cell(0,1);
requests = 0;
hits = 0;
misses = 0;
evictions = 0;

simulateCached = @local_simulate;
getStats = @local_stats;
clearCache = @local_clear;

    function sim = local_simulate(theta)
        theta = theta(:).';
        assert(numel(theta)==6,'Expected six native mean parameters.');
        requests = requests + 1;

        idx = [];
        for jj = size(cacheTheta,1):-1:1
            if isequal(theta,cacheTheta(jj,:))
                idx = jj;
                break
            end
        end

        if ~isempty(idx)
            hits = hits + 1;
            sim = cacheResult{idx};
            return
        end

        misses = misses + 1;
        sim = rawSimulator(theta);

        if size(cacheTheta,1) >= maxEntries
            cacheTheta(1,:) = [];
            cacheResult(1) = [];
            evictions = evictions + 1;
        end
        cacheTheta(end+1,:) = theta;
        cacheResult{end+1,1} = sim;
    end

    function s = local_stats()
        s = struct();
        s.requests = requests;
        s.hits = hits;
        s.misses = misses;
        s.evictions = evictions;
        s.entries = size(cacheTheta,1);
        s.maxEntries = maxEntries;
        if requests>0
            s.hitFraction = hits/requests;
        else
            s.hitFraction = NaN;
        end
    end

    function local_clear()
        cacheTheta = zeros(0,6);
        cacheResult = cell(0,1);
        requests = 0;
        hits = 0;
        misses = 0;
        evictions = 0;
    end
end
