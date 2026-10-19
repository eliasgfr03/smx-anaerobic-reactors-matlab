function result = run_oem_own_v1(b)
%RUN_OBSERVATION_ERROR_SELECTION Historical M0 joint MLE for ONE reactor.
%   Full scientific execution, not a zero-forward validator or a new M1 fit.
%   Source method: three families, four starts each, fmincon SEARCH/POLISH.
%   Existing runs cannot be resumed or overwritten by this entrypoint.
assert(nargin==1 && exist('fmincon','file')==2 && ...
    ~verLessThan('matlab','9.13'),'JWPE:OEM:Dependency', ...
    'Select reactor/runID; MATLAB R2022b+ and Optimization Toolbox required.');
previousRNG = rng;
restoreRNG = onCleanup(@()rng(previousRNG));
inputs=b.inputs;
cfg = inputs.cfg;
folder=jwpe_own_output_v1(b.folder);
state = struct('status','CREATED','role',inputs.role, ...
    'identity',inputs.identity,'cfg',cfg,'completedStarts',0, ...
    'pendingStart',struct([]),'modelRuns',{cell(3,1)}, ...
    'rawBudget',jwpe_oem_budget('create',struct(),cfg.public.rawForwardHardMax), ...
    'rngInitial',rng,'rngCurrent',rng,'runDirectory',folder);
jwpe_run_write(folder,'run_spec.mat',inputs,'mat',false);
jwpe_run_write(folder,'run_state.mat',state,'mat',false);
problem = [];
try
    % Record the required anchor before its builder can enter the solver.
    % A builder error leaves one explicitly uncertain attempt, never zero.
    state.rawBudget = jwpe_oem_budget('begin',state.rawBudget, ...
        cfg.public.rawForwardHardMax);
    state.status = 'ANCHOR_PENDING';
    jwpe_run_write(folder,'run_state.mat',state,'mat',true);
    problem = jwpe_oem_problem(inputs);
    state.rawBudget = problem.getRawBudget();
    jwpe_run_write(folder,'run_state.mat',state,'mat',true);
    for im=1:3
        modelName = cfg.modelNames{im};
        bank = JWPE_OEM_start_bank_v1_3(problem,cfg,modelName);
        runSlots = cell(4,1);
        for is=1:4
            label = sprintf('%s_%s_start_%02d',inputs.reactor,modelName,is);
            state.pendingStart = struct('model',modelName,'start',is,'label',label);
            state.status = 'RUNNING';
            state.rngCurrent = rng;
            jwpe_run_write(folder,'run_state.mat',state,'mat',true);
            rr = JWPE_OEM_optimize_v1_3(problem,cfg,modelName, ...
                bank.theta(is,:),bank.error(is,:),label);
            runSlots{is} = rr;
            runs = vertcat(runSlots{1:is});
            state.modelRuns{im} = runs;
            state.completedStarts = state.completedStarts+1;
            state.pendingStart = struct([]);
            state.rawBudget = problem.getRawBudget();
            state.rngCurrent = rng;
            jwpe_run_write(folder,'run_state.mat',state,'mat',true);
        end
    end
    result = jwpe_oem_assemble(inputs,state.modelRuns,problem.getRawBudget());
    result.rngInitial = state.rngInitial;
    result.rngFinal = rng;
    state.status = 'NUMERICALLY_COMPLETE_REVIEW_REQUIRED';
    jwpe_run_write(folder,'run_state.mat',state,'mat',true);
    jwpe_oem_finalize(folder,result);
    state.status = 'COMPLETE_REVIEW_REQUIRED';
    jwpe_run_write(folder,'run_state.mat',state,'mat',true);
catch ME
    state.status = 'FAILED_REVIEW_REQUIRED';
    state.failure = struct('identifier',ME.identifier,'message',ME.message);
    if ~isempty(problem)
        state.rawBudget = problem.getRawBudget();
    end
    state.rngCurrent = rng;
    jwpe_run_write(folder,'run_state.mat',state,'mat',true);
    rethrow(ME)
end
clear restoreRNG
end
