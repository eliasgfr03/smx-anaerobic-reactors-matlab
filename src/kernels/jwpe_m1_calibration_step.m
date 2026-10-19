function f = jwpe_m1_calibration_step(u,runDirectory)
%   A native optimizer checkpoint captures only this callback and its run
%   directory. Mutable counts/cache are loaded from the one consolidated
%   state file, never from a serialized nested-function workspace.
q = load(fullfile(runDirectory,'run_state.mat'),'payload');
state = q.payload;
assert(strcmp(state.runDirectory,char(runDirectory)) && ...
    ~state.searchFinished,'JWPE:Public:State','Wrong or closed objective run.');
u = double(u(:).');
assert(numel(u)==4 && all(isfinite(u)) && all(u>=0) && all(u<=1), ...
    'JWPE:Public:Support','Expected four normalized coordinates in [0,1].');
indices = state.cfg.freeIndices;
theta = [state.cfg.fixedKd, ...
    jwpe_opt_denormalize(u,state.cfg.lower(indices),state.cfg.upper(indices))];
key = jwpe_calibration_key(theta);
cacheIndex = find(state.cacheKeys==string(key),1);
request = struct('phase','OPT','theta',theta,'key',key, ...
    'cacheHit',~isempty(cacheIndex));
state = jwpe_calibration_record('begin',state,request);
jwpe_run_write(runDirectory,'run_state.mat',state,'mat',true);
try
    if request.cacheHit
        e = state.cache{cacheIndex};
    else
        e = jwpe_m1_calibration_eval(state.context,theta,state.cfg,'OPT');
    end
    state = jwpe_calibration_record('complete',state,e);
    jwpe_run_write(runDirectory,'run_state.mat',state,'mat',true);
catch ME
    failure = struct('identifier',ME.identifier,'message',ME.message);
    state = jwpe_calibration_record('fail',state,failure);
    jwpe_run_write(runDirectory,'run_state.mat',state,'mat',true);
    rethrow(ME)
end
f = e.nll;
if mod(state.optimizerCalls,state.cfg.progressEvery)==0
    if isempty(state.best)
        bestNLL = Inf;
    else
        bestNLL = state.best.nll;
    end
    fprintf('M1 %s | calls %d/%d | forwards %d | cache %d | NLL %.12f\n', ...
        state.cfg.reactor,state.optimizerCalls,state.cfg.budget.optimizerCalls, ...
        state.rawForwards,state.cacheHits,bestNLL);
end
end
