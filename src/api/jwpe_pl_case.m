function cfg=jwpe_pl_case(model,reactor,caseID,normalizedStarts,anchor)
%JWPE_PL_CASE Complete one method recipe with explicit starts and own anchor.
% normalizedStarts: rows of nuisance/anchor coordinates on [0,1].
% anchor: own independently rechecked result with theta,nll. No saved article fit.
cases=jwpe_pl_cases(model,reactor);hit=find(strcmp({cases.id},caseID));
assert(isscalar(hit),'JWPE:PL:Case','Unknown or duplicate case.');cfg=cases(hit);
assert(isstruct(anchor) && isscalar(anchor) && all(isfield(anchor,{'theta','nll'})) && ...
    isscalar(anchor.nll) && isfinite(anchor.nll) && all(isfinite(anchor.theta)), ...
    'JWPE:PL:Anchor','Supply an own independently rechecked anchor.');
assert(isnumeric(normalizedStarts) && ~isempty(normalizedStarts) && ...
    all(isfinite(normalizedStarts),'all') && ...
    all(normalizedStarts>=0 & normalizedStarts<=1,'all'));
if strcmp(model,'M0')
    assert(numel(anchor.theta)==6 && size(normalizedStarts,2)==numel(cfg.lb));
    cfg.initialNormalized=struct('X',normalizedStarts,'Fval',[],'Ineq',[]);
    if strcmp(reactor,'PF')
        cfg.initial=cfg.initialNormalized;cfg.seedMode='normalized_explicit_inputs';
    end
else
    assert(numel(anchor.theta)==5 && size(normalizedStarts,2)==numel(cfg.freeIndices));
    cfg.initialX=normalizedStarts;cfg.anchorNLL=anchor.nll;
    cfg.baseTheta=anchor.theta(:).';cfg.initialTheta=cfg.baseTheta;
    if isfield(cfg.options,'MinSurrogatePoints') && ischar(cfg.options.MinSurrogatePoints)
        assert(strcmp(cfg.options.MinSurrogatePoints,'max(20,2*numberOfVariables)'));
        cfg.options.MinSurrogatePoints=max(20,2*numel(cfg.freeIndices));
    end
    info=jwpe_package_info();
    cfg.catalogSHA256=m1_hash_v1(fullfile(info.packageRoot,'analyses','recipes',[char(model) '.json']),'file');
end
end
