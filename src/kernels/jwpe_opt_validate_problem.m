function problem = jwpe_opt_validate_problem(problem,cfg)
%JWPE_OPT_VALIDATE_PROBLEM Validate the reusable optimization-stage contract.
%
% REQUIRED FIELDS
%   name, lbPhysical, ubPhysical, evaluateFcn, recheckFcn, outputDir.
%
% evaluateFcn(xPhysical) returns either a scalar objective or a struct with
% field objective (preferred) or nll. Optional common diagnostic fields are
% recorded automatically when present.
%
% recheckFcn(xPhysical) must perform an independent evaluation of the best
% point. For mechanistic inference this should bypass any exact forward cache.

required = {'name','lbPhysical','ubPhysical','evaluateFcn','recheckFcn','outputDir'};
for i=1:numel(required)
    assert(isfield(problem,required{i}), ...
        'Optimization problem is missing required field: %s',required{i});
end

problem.name = char(string(problem.name));
problem.outputDir = char(string(problem.outputDir));
problem.lbPhysical = double(problem.lbPhysical(:).');
problem.ubPhysical = double(problem.ubPhysical(:).');

nvar = numel(problem.lbPhysical);
assert(nvar==cfg.nvar,'Problem dimension differs from optimization config.');
assert(numel(problem.ubPhysical)==nvar,'Lower/upper bound sizes differ.');
assert(all(isfinite(problem.lbPhysical)) && all(isfinite(problem.ubPhysical)), ...
    'surrogateopt requires finite bounds for every variable.');
assert(all(problem.ubPhysical>problem.lbPhysical), ...
    'Each optimization variable requires ub > lb.');
assert(isa(problem.evaluateFcn,'function_handle'),'evaluateFcn must be a function handle.');
assert(isa(problem.recheckFcn,'function_handle'),'recheckFcn must be a function handle.');

if ~isfield(problem,'parameterNames') || isempty(problem.parameterNames)
    problem.parameterNames = "x" + string(1:nvar);
else
    problem.parameterNames = string(problem.parameterNames(:).');
    assert(numel(problem.parameterNames)==nvar, ...
        'parameterNames must contain one name per variable.');
end

if ~isfield(problem,'isExpensive'); problem.isExpensive = true; end
if ~isfield(problem,'objectiveLimit'); problem.objectiveLimit = []; end
if ~isfield(problem,'constraintFcnPhysical'); problem.constraintFcnPhysical = []; end
if ~isempty(problem.constraintFcnPhysical)
    assert(isa(problem.constraintFcnPhysical,'function_handle'), ...
        'constraintFcnPhysical must be empty or a function handle.');
end

if isfield(problem,'initialPointsPhysical') && ~isempty(problem.initialPointsPhysical)
    assert(size(problem.initialPointsPhysical,2)==nvar, ...
        'initialPointsPhysical must have nvar columns.');
end

if ~isfolder(problem.outputDir)
    mkdir(problem.outputDir);
end
end
