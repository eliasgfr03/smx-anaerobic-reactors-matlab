function api = jwpe_fixed_session_v1(ctx,cfg,outDir)
%JWPE_FIXED_SESSION_V1 Account before each forward, compact ledger/in-memory cache.
% No disk trajectory cache, no solver checkpoint, no retries. Separate OPT,
% closure pattern/poll and independent recheck quotas, including failures.
cache=containers.Map('KeyType','char','ValueType','any');
counts=struct('rawForwards',0,'cacheHits',0,'objectiveCalls',0, ...
    'patternCalls',0,'pollCalls',0,'rechecks',0,'sigmaProfiles',0, ...
    'sigmaInnerCalls',0,'sigmaInnerFunctionEvaluations',0, ...
    'pendingSigmaProfiles',0,'sigmaInnerCountsComplete',true, ...
    'invalidNegative',0,'failures',0);
entries={}; bestNLL=Inf; bestTheta=[];
api=struct('evaluate',@evaluate,'best',@best,'snapshot',@snapshot);
    function e=evaluate(theta,phase)
        theta=double(theta(:).'); phase=char(phase);
        if strcmp(phase,'OPT')
            assert(counts.objectiveCalls<cfg.objectiveCap,'JWPE:P05B:Budget','Objective cap.');
            counts.objectiveCalls=counts.objectiveCalls+1;
        elseif strcmp(phase,'PATTERNSEARCH')
            assert(counts.patternCalls<cfg.closure.MaxFunctionEvaluations);
            counts.patternCalls=counts.patternCalls+1;
        elseif strcmp(phase,'DETERMINISTIC_POLLS')
            assert(counts.pollCalls<cfg.closure.maxPollForwards);
            counts.pollCalls=counts.pollCalls+1;
        else
            assert(strcmp(phase,'RECHECK') && counts.rechecks==0);
            counts.rechecks=1;
        end
        key=sprintf('%.17g,',theta);
        hit=~strcmp(phase,'RECHECK') && isKey(cache,key);
        row=struct('phase',phase,'theta',theta,'cacheHit',hit, ...
            'status','PENDING','nll',NaN,'rawForwardIncrement',double(~hit));
        if hit
            counts.cacheHits=counts.cacheHits+1;
        else
            reserve=double(~strcmp(phase,'RECHECK'));
            assert(counts.rawForwards<cfg.hardBudget-reserve, ...
                'JWPE:P05B:Budget','Raw-forward cap, preserving final recheck.');
            counts.rawForwards=counts.rawForwards+1;
        end
        entries{end+1}=row; idx=numel(entries); persist();
        try
            if hit, e=cache(key); else, e=jwpe_fixed_evaluate_v1(ctx,theta,cfg,phase,@charge_sigma); end
            if ~hit && e.sigmaProfiled
                counts.sigmaInnerCalls=counts.sigmaInnerCalls+height(e.errorFit.startRuns);
                counts.sigmaInnerFunctionEvaluations=counts.sigmaInnerFunctionEvaluations+ ...
                    e.errorFit.totalFunctionCount;
                counts.pendingSigmaProfiles=counts.pendingSigmaProfiles-1;
                counts.sigmaInnerCountsComplete=counts.pendingSigmaProfiles==0;
            end
            if e.eligible
                row.status='COMPLETE_VALID'; row.nll=e.nll;
                row.sigmaA=e.sigmaA; row.sigmaP=e.sigmaP; row.classification=e.classification;
                if ~hit && ~strcmp(phase,'RECHECK')
                    % Cache only compact predictions/fit, never full mechanistic trajectories.
                    cache(key)=e;
                end
                if ~strcmp(phase,'RECHECK') && e.nll<bestNLL
                    bestNLL=e.nll; bestTheta=theta;
                end
            else
                assert(strcmp(phase,'OPT') && strcmp(cfg.reactor,'PF'));
                counts.invalidNegative=counts.invalidNegative+1;
                row.status='COMPLETE_INVALID_NEGATIVE_STATE';
                row.classification=e.classification;
                row.minimumLocation=e.minimumLocation;
            end
            entries{idx}=row; persist();
        catch ME
            counts.failures=counts.failures+1; row.status='FAILED';
            row.identifier=ME.identifier; row.message=ME.message;
            entries{idx}=row; persist(); rethrow(ME)
        end
    end
    function [theta,nll]=best()
        assert(isfinite(bestNLL) && numel(bestTheta)==5, ...
            'JWPE:P05B:Endpoint','No finite eligible endpoint.');
        theta=bestTheta; nll=bestNLL;
    end
    function s=snapshot()
        s=struct('counts',counts,'entries',{entries});
    end
    function charge_sigma()
        counts.sigmaProfiles=counts.sigmaProfiles+1;
        counts.pendingSigmaProfiles=counts.pendingSigmaProfiles+1;
        counts.sigmaInnerCountsComplete=false;
        persist();
    end
    function persist()
        jwpe_m1_pl_io('ledger',outDir,snapshot());
    end
end
