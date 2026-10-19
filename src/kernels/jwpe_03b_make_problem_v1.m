function [problem,cfgOpt,initialPoint] = jwpe_03b_make_problem_v1(model,ctx,cfgCore,cfgStage,outDir)

model = upper(string(model));
assert(any(model==["G1","A1"]),'model must be G1 or A1.');

switch model
    case "G1"
        initialPoint = ctx.thetaRef;
        cfgOpt = jwpe_opt_master_config(6);
        problem = struct();
        problem.name = sprintf('%s_03B_G1_phase12',ctx.reactor);
        problem.lbPhysical = cfgStage.G1.bounds(:,1).';
        problem.ubPhysical = cfgStage.G1.bounds(:,2).';
        problem.parameterNames = cfgStage.G1.parameterNames;
        problem.evaluateFcn = @(x)jwpe_03b_evaluate_g1_v1(x,ctx,cfgCore,false,false);
        problem.recheckFcn = @(x)jwpe_03b_evaluate_g1_v1(x,ctx,cfgCore,true,true);
    case "A1"
        initialPoint = ctx.thetaRef(1:3);
        cfgOpt = jwpe_opt_master_config(3);
        problem = struct();
        problem.name = sprintf('%s_03B_A1_phase12',ctx.reactor);
        problem.lbPhysical = cfgStage.A1.bounds(:,1).';
        problem.ubPhysical = cfgStage.A1.bounds(:,2).';
        problem.parameterNames = cfgStage.A1.parameterNames;
        problem.evaluateFcn = @(x)jwpe_03b_evaluate_a1_v1(x,ctx,cfgCore,cfgStage,false,false,[]);
        problem.recheckFcn = @(x)jwpe_03b_evaluate_a1_v1(x,ctx,cfgCore,cfgStage,true,true,[]);
end

assert(strcmp(cfgOpt.version,'JWPE_OPTIMIZATION_CORE_v1_0_1'), ...
    'Validated Optimization Core v1.0.1 is required.');
assert(cfgOpt.maxFunctionEvaluations==50, ...
    'Frozen master surrogate budget must remain 50.');
assert(cfgOpt.minSurrogatePoints==max(8,cfgOpt.nvar+1), ...
    'Unexpected master MinSurrogatePoints.');

problem.outputDir = outDir;
problem.initialPointsPhysical = initialPoint;
problem.objectiveLimit = [];
problem.constraintFcnPhysical = @(x)jwpe_03b_native_ineq_v1(x,cfgCore);
problem.isExpensive = strcmpi(ctx.reactor,'PF');
end
