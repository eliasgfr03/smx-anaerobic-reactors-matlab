function result = jwpe_m1_pl_closure(ctx,cfg,outDir)
%JWPE_M1_PL_CLOSURE One source-pinned closure, no extra adaptive discovery.
% Reuse the source initial vector. Patternsearch evaluates its starting point;
% this evaluation establishes the new-run incumbent without a pre-forward or
% reliance on a rounded historical NLL. The first trial must be the start.
assert(strcmp(cfg.role,'CLOSURE_ANCHOR_REUSE'));
session=jwpe_m1_pl_session(ctx,cfg,outDir); c=cfg.closure;
z0=(cfg.initialTheta-cfg.lower)./(cfg.upper-cfg.lower);
first=true;
opts=optimoptions('patternsearch','Display','off','Algorithm',c.algorithm, ...
    'PollMethod',c.PollMethod,'UseCompletePoll',c.UseCompletePoll, ...
    'SearchFcn',[],'ScaleMesh',c.ScaleMesh,'UseParallel',false, ...
    'UseVectorized',false,'InitialMeshSize',c.InitialMeshSize, ...
    'MaxMeshSize',c.MaxMeshSize,'MeshExpansionFactor',c.MeshExpansionFactor, ...
    'MeshContractionFactor',c.MeshContractionFactor, ...
    'MeshTolerance',c.MeshTolerance,'MaxFunctionEvaluations',c.MaxFunctionEvaluations);
[~,~,exitflag,output]=patternsearch(@objective,z0,[],[],[],[],zeros(1,5),ones(1,5),[],opts);
[theta,bestNLL]=session.best(); z=(theta-cfg.lower)./(cfg.upper-cfg.lower);
for mesh=double(c.pollMeshes(:).')
    movedAtCap=false;
    for p=1:c.maxCompletePollsPerMesh
        currentNLL=bestNLL; trialZ=zeros(0,5); trialNLL=zeros(0,1);
        for j=1:5
            for direction=[-1,1]
                candidate=z; candidate(j)=candidate(j)+direction*mesh;
                if candidate(j)<0 || candidate(j)>1, continue; end
                trialZ(end+1,:)=candidate; %#ok<AGROW>
                e=session.evaluate(cfg.lower+candidate.*(cfg.upper-cfg.lower), ...
                    'DETERMINISTIC_POLLS');
                trialNLL(end+1,1)=e.nll; %#ok<AGROW>
            end
        end
        assert(~isempty(trialNLL));
        [candidateNLL,k]=min(trialNLL);
        % Source closures retain every best evaluated point, including small
        % improvements that do not move the polling centre z.
        [theta,bestNLL]=session.best();
        if currentNLL-candidateNLL>c.moveToleranceNLL
            z=trialZ(k,:); theta=cfg.lower+z.*(cfg.upper-cfg.lower);
            bestNLL=candidateNLL; movedAtCap=p==c.maxCompletePollsPerMesh;
        else
            movedAtCap=false; break
        end
    end
    assert(~movedAtCap,'JWPE:P05B:Closure','HOLD_LOCAL_CAP');
end
% Retain the lowest eligible evaluated point, independently rechecked.
recheck=session.evaluate(theta,'RECHECK');
assert(recheck.eligible && abs(recheck.nll-bestNLL)<=cfg.recheckToleranceNLL, ...
    'JWPE:P05B:Recheck','Closure independent recheck mismatch.');
result=struct('status','COMPLETE_REVIEW_REQUIRED','caseId',cfg.id, ...
    'reactor',cfg.reactor,'role',cfg.role,'initialTheta',cfg.initialTheta, ...
    'theta',theta,'nll',bestNLL,'recheckNLL',recheck.nll, ...
    'recheckDelta',recheck.nll-bestNLL,'endpoint',recheck, ...
    'counts',session.snapshot(),'exitflag',exitflag,'output',output, ...
    'phaseIIIExcluded',true,'maxHorizon_d',94, ...
    'catalogSHA256',cfg.catalogSHA256, ...
    'officialEligible',theta(1)>=0 && theta(1)<=0.06);
    function f=objective(zTrial)
        if first
            assert(isequal(double(zTrial(:).'),z0), ...
                'JWPE:P05B:ClosureStart','Patternsearch did not evaluate the frozen start first.');
            first=false;
        end
        e=session.evaluate(cfg.lower+double(zTrial(:).').*(cfg.upper-cfg.lower),'PATTERNSEARCH');
        f=e.nll;
    end
end
