function e=jwpe_ofl_own_evaluate_v1(z,recheck)
%JWPE_OFL_OWN_EVALUATE_V1 Source mapping/simulation/sigma, exact-vector cache.
s=jwpe_ofl_own_state_v1('get');cfg=s.b.config;ctx=s.b.context;
if strcmp(s.b.analysis,'ofl_g1_screen')
    theta=g1s_map_v1('decode',z,s.b.reactor,cfg);
else
    validateattributes(z,{'numeric'},{'scalar','finite','>=',0,'<=',1});
    theta=z*cfg.kb_support.(s.b.reactor)(2);
end
key=string(m1_hash_v1(typecast(theta,'uint8'),'bytes'));hit=find(s.keys==key,1);
if ~recheck && ~isempty(hit)
    e=s.values{hit};
else
    assert(~s.pending && s.raw<s.rawMax,'JWPE:Own:OFLBudget','Raw limit or unresolved attempt.');
    s.raw=s.raw+1;s.pending=true;jwpe_ofl_own_state_v1('put',s);
    m1_atomic_v1(fullfile(s.folder,'raw_ledger.mat'),struct('raw',s.raw,'pending',true),'mat',true);
    try
        if strcmp(s.b.analysis,'ofl_g1_screen')
            sim=g1s_sim_v1(ctx,theta,cfg,false);
        else
            sim=ofl_sim_v1(ctx,theta,cfg);
        end
        fit=ofl_sigma_own_v1(sim.Cout,ctx,cfg,[],"");
        compact=sim;
        if isfield(compact,'segments'),compact=rmfield(compact,'segments');end
        e=struct('theta',theta,'z',double(z(:).'),'sim',compact,'fit',fit, ...
            'valid',isfinite(fit.nll) && ~strcmp(fit.classification,'ERROR_MODEL_NUMERICAL_HOLD') && ...
            abs(fit.directRecalculationDelta)<=cfg.likelihood.direct_NLL_tolerance);
        if numel(theta)==1,e.kb=theta;end
        assert(e.valid,'JWPE:Own:OFLSigma','Conditional error fit requires review.');
        s.pending=false;
        if ~recheck,s.keys(end+1,1)=key;s.values{end+1}=e;end
    catch ME
        jwpe_ofl_own_state_v1('put',s);rethrow(ME)
    end
end
if ~recheck && (isempty(s.best) || e.fit.nll<s.best.fit.nll),s.best=e;end
jwpe_ofl_own_state_v1('put',s);
m1_atomic_v1(fullfile(s.folder,'raw_ledger.mat'),struct('raw',s.raw,'pending',s.pending),'mat',true);
end
