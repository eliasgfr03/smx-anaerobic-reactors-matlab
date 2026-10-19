function result = run_m1_own_v1(b)
%RUN_M1_OWN_V1 Execute one explicit fixed-Kd calibration job.
% b.inputs contains cfg/context/initialPoints/identity; b.action is new or resume.
% Limits are read from cfg.budget, not inferred from the run identifier.
assert(nargin==1,'JWPE:Public:Execution', ...
    'Specify reactor, new runID and explicit action new or resume.');
runID=b.runID; action=lower(string(b.action));
assert(isscalar(action) && any(action==["new","resume"]), ...
    'JWPE:Public:Execution','Action must be new or resume.');
assert(~verLessThan('matlab','9.13') && exist('surrogateopt','file')==2, ...
    'JWPE:Public:Dependency','MATLAB R2022b+ and Global Optimization Toolbox required.');
inputs=b.inputs;
cfg = inputs.cfg;
runID = char(string(runID));
assert(~isempty(regexp(runID,'^[A-Za-z0-9][A-Za-z0-9_-]{0,31}$','once')), ...
    'JWPE:Public:Path','Use a short runID with letters, digits, _ or -.');
folder=b.folder;
assert(numel(fullfile(folder,'surrogate_checkpoint.mat'))<=245, ...
    'JWPE:Public:Path','Output filename would exceed 245 characters.');
previousRNG = rng;
restoreRNG = onCleanup(@()rng(previousRNG));
if action=="new"
    folder=jwpe_own_output_v1(b.folder);
    rng(cfg.rngSeed,cfg.rngGenerator);
    state = jwpe_m1_calibration_state(inputs);
    state.rngInitial = rng;
    state.rngCurrent = rng;
    state.runDirectory = folder;
    jwpe_run_write(folder,'run_spec.mat',inputs,'mat',false);
    jwpe_run_write(folder,'run_state.mat',state,'mat',false);
else
    assert(isfolder(folder) && isfile(fullfile(folder,'run_state.mat')), ...
        'JWPE:Public:Resume','Requested run state is absent.');
    q = load(fullfile(folder,'run_state.mat'),'payload');
    state = q.payload;
    assert(isequal(state.identity,inputs.identity) && ...
        isequal(state.cfg,cfg) && strcmp(state.runDirectory,folder) && ...
        isempty(state.pending) && state.failures==0 && ...
        state.optimizerCalls<=cfg.budget.optimizerCalls && ...
        state.rawForwards<=cfg.budget.rawForwards, ...
        'JWPE:Public:Resume','Changed, uncertain or failed run cannot resume.');
    rng(state.rngCurrent);
end
checkpoint = fullfile(folder,'surrogate_checkpoint.mat');
if ~state.searchFinished
    if action=="resume"
        assert(isfile(checkpoint),'JWPE:Public:Resume', ...
            'Native optimizer checkpoint is absent; do not restart silently.');
        [~,~,exitflag,output,trials] = surrogateopt(checkpoint);
    else
        indices = cfg.freeIndices;
        initial = struct('X',jwpe_opt_normalize(inputs.initialPoints(:,indices), ...
            cfg.lower(indices),cfg.upper(indices)));
        options = optimoptions('surrogateopt','Display',cfg.surrogate.Display, ...
            'MaxFunctionEvaluations',cfg.budget.optimizerCalls, ...
            'MaxTime',cfg.surrogate.MaxTime, ...
            'UseParallel',false,'UseVectorized',false, ...
            'CheckpointFile',checkpoint,'InitialPoints',initial);
        objective = @(u)jwpe_m1_calibration_step(u,folder);
        [~,~,exitflag,output,trials] = surrogateopt(objective, ...
            zeros(1,4),ones(1,4),options);
    end
    q = load(fullfile(folder,'run_state.mat'),'payload');
    state = jwpe_calibration_record('search_complete',q.payload, ...
        struct('exitflag',exitflag,'output',output,'trials',trials));
    jwpe_run_write(folder,'run_state.mat',state,'mat',true);
end
if isempty(state.recheck)
    request = struct('phase','RECHECK','theta',state.best.theta, ...
        'key',jwpe_calibration_key(state.best.theta),'cacheHit',false);
    state = jwpe_calibration_record('begin',state,request);
    jwpe_run_write(folder,'run_state.mat',state,'mat',true);
    try
        e = jwpe_m1_calibration_eval(state.context,request.theta,cfg,'RECHECK');
        state = jwpe_calibration_record('complete',state,e);
        jwpe_run_write(folder,'run_state.mat',state,'mat',true);
    catch ME
        state = jwpe_calibration_record('fail',state, ...
            struct('identifier',ME.identifier,'message',ME.message));
        jwpe_run_write(folder,'run_state.mat',state,'mat',true);
        rethrow(ME)
    end
end
result = jwpe_m1_calibration_finalize(folder,state);
clear restoreRNG
end
