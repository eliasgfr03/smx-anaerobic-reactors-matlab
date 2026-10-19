function [problem,cfgOpt,x0] = jwpe_03b_log2_make_problem_v1(ctx,g1,cfgCore,cfgStage,outDir)

x0=jwpe_03b_log2_initial_from_g1_v1(g1,cfgStage);
cfgOpt=jwpe_opt_master_config(5);
assert(strcmp(cfgOpt.version,'JWPE_OPTIMIZATION_CORE_v1_0_1'), ...
    'Validated patched Optimization Core v1.0.1 is required.');
assert(cfgOpt.maxFunctionEvaluations==50 && cfgOpt.minSurrogatePoints==8, ...
    'Frozen surrogate policy mismatch.');

problem=struct();
problem.name=sprintf('%s_03B_LOG2_phase12',ctx.reactor);
problem.lbPhysical=cfgStage.LOG2.bounds(:,1).';
problem.ubPhysical=cfgStage.LOG2.bounds(:,2).';
problem.parameterNames=cfgStage.LOG2.parameterNames;
problem.evaluateFcn=@(x)jwpe_03b_log2_evaluate_v1(x,ctx,cfgCore,cfgStage,false);
problem.recheckFcn=@(x)jwpe_03b_log2_evaluate_v1(x,ctx,cfgCore,cfgStage,true);
problem.outputDir=outDir;
problem.initialPointsPhysical=x0;
problem.objectiveLimit=[];
problem.constraintFcnPhysical=@(x)jwpe_03b_native_ineq_v1(x(1:3),cfgCore);
problem.isExpensive=strcmpi(ctx.reactor,'PF');
end
