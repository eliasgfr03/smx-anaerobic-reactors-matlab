function result = jwpe_m1_pl_search(ctx,cfg,outDir)
%JWPE_M1_PL_SEARCH One frozen conditional search, then independent recheck.
assert(strcmp(cfg.role,'CONDITIONAL_SEARCH'));
session=jwpe_m1_pl_session(ctx,cfg,outDir);
rng(cfg.seed,'twister'); rngInitial=rng;
opts=optimoptions('surrogateopt','Display','off');
names=fieldnames(cfg.options);
for i=1:numel(names)
    name=names{i}; value=cfg.options.(name);
    if isstruct(value)
        assert(isfield(value,'nonfinite'));
        switch value.nonfinite
            case 'inf', value=Inf;
            case '-inf', value=-Inf;
            otherwise, error('JWPE:P05B:Options','Invalid option token.');
        end
    end
    assert(isprop(opts,name),'JWPE:P05B:Options','Unsupported frozen option: %s',name);
    opts.(name)=value;
end
opts.InitialPoints=struct('X',cfg.initialX);
% Explicitly omit CheckpointFile; no scientific resume is silently inferred.
[~,~,exitflag,output,trials]=surrogateopt(@objective,zeros(1,4),ones(1,4),opts);
[theta,bestNLL]=session.best();
recheck=session.evaluate(theta,'RECHECK');
assert(recheck.eligible && abs(recheck.nll-bestNLL)<=cfg.recheckToleranceNLL, ...
    'JWPE:P05B:Recheck','Conditional independent recheck mismatch.');
result=struct('status','COMPLETE_REVIEW_REQUIRED','caseId',cfg.id, ...
    'reactor',cfg.reactor,'role',cfg.role,'theta',theta,'nll',bestNLL, ...
    'recheckNLL',recheck.nll,'recheckDelta',recheck.nll-bestNLL, ...
    'endpoint',recheck,'counts',session.snapshot(), ...
    'exitflag',exitflag,'output',output,'trials',trials, ...
    'rngInitial',rngInitial,'rngFinal',rng,'phaseIIIExcluded',true, ...
    'maxHorizon_d',94,'catalogSHA256',cfg.catalogSHA256, ...
    'anchorPolicy',cfg.anchorPolicy,'officialEligible',theta(1)>=0 && theta(1)<=0.06);
if ~isempty(cfg.anchorNLL) && strcmp(cfg.anchorPolicy,'STOP_RECHECK_IMPROVEMENT_GT_5E-4') && ...
        recheck.nll<cfg.anchorNLL-5e-4
    result.status='ANCHOR_CHALLENGE';
    jwpe_m1_pl_io('save',outDir,'result',result);
    error('JWPE:P05B:Anchor','ANCHOR_CHALLENGE: no automatic closure or promotion.');
end
    function f=objective(u)
        thetaTrial=zeros(1,5);
        thetaTrial(cfg.freeIndices)=cfg.lower+double(u(:).').*(cfg.upper-cfg.lower);
        thetaTrial(cfg.fixedIndex)=cfg.fixedValue;
        e=session.evaluate(thetaTrial,'OPT');
        f=e.nll; % NaN only for classified PF OPT negative state.
    end
end
