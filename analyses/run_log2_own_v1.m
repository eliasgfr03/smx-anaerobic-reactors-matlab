function result = run_log2_own_v1(b)
%RUN_CAPACITY_LOG2 One LOG2 search against an explicitly selected frozen G1.
% Does not optimize/evaluate G1 again or automatically select the latest run.
short=isfield(b,'shortBudget');
if short
    assert(strcmp(b.mode,'test') && isequal(b.shortBudget,24), ...
        'JWPE:Capacity:Short','Short budget requires test mode and 24 calls.');
end
if isfield(b,'shortSeed') || isfield(b,'shortCheckpoint')
    assert(short,'JWPE:Capacity:Short','Explicit short options require test mode.');
end
if isfield(b,'shortSeed')
    validateattributes(b.shortSeed,{'double'},{'scalar','integer','nonnegative','finite'});
end
if isfield(b,'shortCheckpoint')
    assert(islogical(b.shortCheckpoint) && isscalar(b.shortCheckpoint), ...
        'JWPE:Capacity:Short','Checkpoint option must be a logical scalar.');
end
g1=b.g1; reference=b.g1Reference;
reactor=b.reactor; folder=jwpe_own_output_v1(b.folder);
assert(numel(fullfile(folder,'LOG2','surrogateopt_checkpoint.mat'))<=245, ...
    'JWPE:Capacity:Path','Choose a shorter run identifier.');
state=struct('status','PREPARING','stage','LOG2','reactor',char(reactor), ...
    'rawBudgets',struct(),'failure',struct('identifier','','message',''));
oldRNG=rng; restoreRNG=onCleanup(@()rng(oldRNG));
try
    ctx=capacity_inputs_own_v1(b,@progress);
    assert(isequal(g1.observed_ug_L(:),ctx.calibrationObserved_ug_L(:)), ...
        'JWPE:Capacity:Reference','Frozen G1 and current data differ.');
    core=b.core;
    cfg=b.capacityConfig; identity=b.identity;
    state.rawBudgets=ctx.getRawBudgets();
    spec=struct('stage','LOG2','identity',identity,'reference',reference, ...
        'core',core,'capacity',cfg,'optimizer',jwpe_opt_master_config(5), ...
        'rawMaxStage',51,'phaseIIIAccessed',false,'figuresGenerated',false);
    if short
        spec.masterOptimizer=spec.optimizer;
        spec.optimizer.maxFunctionEvaluations=b.shortBudget;
        spec.optimizer.allowNonstandardBudget=true; spec.optimizer.validationMode=true;
        spec.optimizer.checkpointPolicy='never'; spec.optimizer.display='off';
        if isfield(b,'shortSeed'),spec.optimizer.seed=b.shortSeed;end
        if isfield(b,'shortCheckpoint') && b.shortCheckpoint,spec.optimizer.checkpointPolicy='always';end
        spec.effectiveRawMaxEach=b.shortBudget+1;spec.testOnly=true;
    end
    jwpe_run_write(folder,'run_spec.json',jsonencode(spec),'text',false);
    save_state(); modelDir=fullfile(folder,'LOG2'); mkdir(modelDir);
    [problem,opt]=jwpe_03b_log2_make_problem_v1(ctx,g1,core,cfg,modelDir);
    if short
        opt.maxFunctionEvaluations=b.shortBudget;
        opt.allowNonstandardBudget=true; opt.validationMode=true;
        opt.checkpointPolicy='never'; opt.display='off';
        if isfield(b,'shortSeed'),opt.seed=b.shortSeed;end
        if isfield(b,'shortCheckpoint') && b.shortCheckpoint,opt.checkpointPolicy='always';end
    end
    state.status='RUNNING_LOG2'; save_state();
    fit=jwpe_opt_run_surrogate(problem,opt);
    assert(strcmp(fit.status,'PASS') && fit.recheckPASS && fit.recheck.valid ...
        && fit.objectiveStats.errorCount==0, ...
        'JWPE:Capacity:Recheck','Optimizer/recheck requires review.');
    cases=struct('G1',struct('recheck',g1,'sourceRole',reference.role),'LOG2',fit);
    result=jwpe_capacity_assemble(ctx,cases,'LOG2',identity,ctx.getRawBudgets(),reference);
    jwpe_capacity_finalize(folder,result);
    state.status='COMPLETE'; save_state();
catch ME
    state.status='INCOMPLETE_STOP';
    state.failure=struct('identifier',ME.identifier,'message',ME.message);
    save_state(); rethrow(ME)
end
clear restoreRNG
    function progress(budgets)
        state.rawBudgets=budgets; save_state();
    end
    function save_state()
        jwpe_run_write(folder,'run_state.json',jsonencode(state),'text', ...
            isfile(fullfile(folder,'run_state.json')));
    end
end
