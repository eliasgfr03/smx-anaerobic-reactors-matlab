function [initial,stats]=pf_pl_prepare_seeds(cfg,fast,recheck,anchorNLL)
%PF_PL_PREPARE_SEEDS Source initial geometry and pre-search budget accounting.
% Scientific callbacks are supplied only by the explicitly invoked controller.
stats=struct('newSeedEvaluations',0,'rejectedSeedRows',0,'earlyChallenge',false, ...
    'challengeX',[],'challengeSearchNLL',[],'challengeRecheck',[], ...
    'seedObjectives',[],'remainingOptimizerCap',cfg.totalNewObjectiveCap);
if strcmp(cfg.seedMode,'normalized_explicit_inputs')
    initial=cfg.initial;
    return
end
X=double(cfg.initial.physicalX); known=logical(cfg.initial.knownFlags(:));
F=nan(size(X,1),1); values=cfg.initial.knownValues;
for i=1:numel(values); F(values(i).row)=values(i).value; end
assert(numel(known)==size(X,1) && all(isfinite(F(known))), ...
    'PFPort:Seed','Missing exact known objective.');
for i=1:size(X,1)
    if known(i); continue; end
    e=fast(X(i,:)); stats.newSeedEvaluations=stats.newSeedEvaluations+1;
    F(i)=e.objective;
    if isfinite(F(i)) && F(i)<anchorNLL-5e-4
        r=recheck(X(i,:));
        if r.valid && r.objective<anchorNLL-5e-4
            stats.earlyChallenge=true; stats.challengeX=X(i,:);
            stats.challengeSearchNLL=F(i); stats.challengeRecheck=r;
            initial=[]; stats.seedObjectives=F; return
        end
    end
end
good=isfinite(F); stats.rejectedSeedRows=nnz(~good); stats.seedObjectives=F;
stats.remainingOptimizerCap=cfg.totalNewObjectiveCap-stats.newSeedEvaluations;
assert(stats.remainingOptimizerCap>=max(8,cfg.config.nvar+1),'JWPE:Public:Budget', ...
    'Insufficient remaining PF surrogate budget.');
problem=struct('initialPointsPhysical',X(good,:),'initialFval',F(good), ...
    'lbPhysical',cfg.lb(:).','ubPhysical',cfg.ub(:).');
initial=jwpe_opt_prepare_initial_points(problem);
if isstruct(initial) && ~isfield(initial,'Ineq'); initial.Ineq=[]; end
end
