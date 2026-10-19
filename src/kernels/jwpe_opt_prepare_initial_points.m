function initial = jwpe_opt_prepare_initial_points(problem)
%
% If exact objective values are already known, they are carried in Fval so
% again. This implements the project rule: never recompute a known forward
% without a reason.

initial = [];
if ~isfield(problem,'initialPointsPhysical') || isempty(problem.initialPointsPhysical)
    return
end

Xphys = double(problem.initialPointsPhysical);
U = jwpe_opt_normalize(Xphys,problem.lbPhysical,problem.ubPhysical);
assert(all(isfinite(U),'all') && all(U>=0,'all') && all(U<=1,'all'), ...
    'An initial point lies outside its physical bounds.');

hasFval = isfield(problem,'initialFval') && ~isempty(problem.initialFval);
hasIneq = isfield(problem,'initialIneq') && ~isempty(problem.initialIneq);

if ~hasFval && ~hasIneq
    initial = U;
    return
end

initial = struct();
initial.X = U;
if hasFval
    f = double(problem.initialFval(:));
    assert(numel(f)==size(U,1),'initialFval length must match initial points.');
    assert(all(isfinite(f)),'Known initial objective values must be finite.');
    initial.Fval = f;
end
if hasIneq
    ineq = double(problem.initialIneq);
    assert(size(ineq,1)==size(U,1), ...
        'initialIneq rows must match initial points.');
    initial.Ineq = ineq;
end
end
