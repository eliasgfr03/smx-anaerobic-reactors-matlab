function result = run_capacity_own_v1(b)
%RUN_CAPACITY_G1_A1 Scientific full G1/A1 comparison, one reactor per call.
% No local polish, multistart, automatic continuation, LOG2 or other reactor.
short=isfield(b,'shortBudget');
if short
    assert(strcmp(b.mode,'test') && isequal(b.shortBudget,24), ...
        'JWPE:Capacity:Short','Short budget requires test mode and 24 calls.');
end
reactor=b.reactor; folder=jwpe_own_output_v1(b.folder);
assert(numel(fullfile(folder,'G1','surrogateopt_checkpoint.mat'))<=245, ...
    'JWPE:Capacity:Path','Choose a shorter run identifier.');
state=struct('status','PREPARING','stage','G1_A1','reactor',char(reactor), ...
    'completedModels',{{}},'rawBudgets',struct(),'failure',struct('identifier','','message',''));
oldRNG=rng; restoreRNG=onCleanup(@()rng(oldRNG));
try
    ctx=capacity_inputs_own_v1(b,@progress);
    core=b.core; cfg=b.capacityConfig;
    identity=b.identity;
    state.rawBudgets=ctx.getRawBudgets();
    spec=struct('stage','G1_A1','identity',identity,'core',core,'capacity',cfg, ...
        'optimizer',jwpe_opt_master_config(6),'rawMaxEach',51,'rawMaxStage',102, ...
        'phaseIIIAccessed',false,'figuresGenerated',false);
    if short
        spec.masterOptimizer=spec.optimizer;
        spec.masterRawMaxEach=spec.rawMaxEach;
        spec.masterRawMaxStage=spec.rawMaxStage;
        spec.rawMaxEach=b.shortBudget+1;
        spec.rawMaxStage=2*(b.shortBudget+1);
        spec.optimizer.maxFunctionEvaluations=b.shortBudget;
        spec.optimizer.allowNonstandardBudget=true;
        spec.optimizer.validationMode=true;
        spec.optimizer.checkpointPolicy='never'; spec.optimizer.display='off';
        spec.effectiveRawMaxEach=b.shortBudget+1; spec.testOnly=true;
    end
    jwpe_run_write(folder,'run_spec.json',jsonencode(spec),'text',false);
    save_state(); cases=struct();
    for name={'G1','A1'}
        model=name{1}; modelDir=fullfile(folder,model); mkdir(modelDir);
        state.status=['RUNNING_' model]; save_state();
        [problem,opt]=jwpe_03b_make_problem_v1(model,ctx,core,cfg,modelDir);
        if short
            opt.maxFunctionEvaluations=b.shortBudget;
            opt.allowNonstandardBudget=true; opt.validationMode=true;
            opt.checkpointPolicy='never'; opt.display='off';
        end
        fit=jwpe_opt_run_surrogate(problem,opt);
        assert(strcmp(fit.status,'PASS') && fit.recheckPASS && fit.recheck.valid ...
            && fit.objectiveStats.errorCount==0, ...
            'JWPE:Capacity:Recheck','Optimizer/recheck requires review.');
        cases.(model)=fit;
        state.completedModels{end+1}=model; save_state();
    end
    result=jwpe_capacity_assemble(ctx,cases,'G1_A1',identity,ctx.getRawBudgets());
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
