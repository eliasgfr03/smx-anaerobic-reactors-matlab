function result = jwpe_fixed_search_v1(ctx,cfg,outDir)
assert(any(strcmp(cfg.role,{'ANCHOR_SEARCH','CONDITIONAL_SEARCH'})));
session=jwpe_fixed_session_v1(ctx,cfg,outDir);rng(cfg.seed,'twister');rngInitial=rng;
opts=optimoptions('surrogateopt','Display','off');
names=fieldnames(cfg.options);
for i=1:numel(names)
    name=names{i};value=cfg.options.(name);
    if isstruct(value)
        assert(isfield(value,'nonfinite'));
        if strcmp(value.nonfinite,'inf'),value=Inf;else,assert(strcmp(value.nonfinite,'-inf'));value=-Inf;end
    end
    assert(isprop(opts,name));opts.(name)=value;
end
opts.InitialPoints=struct('X',cfg.initialX);n=numel(cfg.freeIndices);
[~,~,exitflag,output,trials]=surrogateopt(@objective,zeros(1,n),ones(1,n),opts);
[theta,bestNLL]=session.best();recheck=session.evaluate(theta,'RECHECK');
assert(recheck.eligible && theta(1)==0.020 && abs(recheck.nll-bestNLL)<=cfg.recheckToleranceNLL);
result=struct('status','COMPLETE_REVIEW_REQUIRED','caseId',cfg.id,'reactor',cfg.reactor, ...
    'role',cfg.role,'theta',theta,'nll',bestNLL,'recheckNLL',recheck.nll, ...
    'recheckDelta',recheck.nll-bestNLL,'endpoint',recheck,'counts',session.snapshot(), ...
    'exitflag',exitflag,'output',output,'trials',trials,'rngInitial',rngInitial, ...
    'rngFinal',rng,'phaseIIIExcluded',true,'maxHorizon_d',94,'fixedKd',0.020, ...
    'catalogSHA256',cfg.catalogSHA256,'anchorPolicy',cfg.anchorPolicy,'officialEligible',true);
if ~isempty(cfg.anchorNLL) && strcmp(cfg.anchorPolicy,'STOP_RECHECK_IMPROVEMENT_GT_5E-4') && ...
        recheck.nll<cfg.anchorNLL-5e-4
    result.status='ANCHOR_CHALLENGE';jwpe_m1_pl_io('save',outDir,'result',result);
    error('JWPE:Fixed:Anchor','PF_AI_DELTA_MATERIAL_ANCHOR_CHALLENGE');
end
    function f=objective(u)
        e=session.evaluate(jwpe_fixed_theta_v1(u,cfg),'OPT');f=e.nll;
    end
end
