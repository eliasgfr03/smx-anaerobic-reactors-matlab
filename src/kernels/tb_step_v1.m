function [current,S,record,jump2] = tb_step_v1( ...
        current,blockName,S,adapt,n,data,stage,sweep)
%TB_STEP_V1 One symmetric random-walk update of one approved block.

blockName = upper(string(blockName));
if blockName=="MECHANISTIC"
    index = data.cfg.blocks.mechanistic;
elseif blockName=="ERROR"
    index = data.cfg.blocks.error;
else
    error('JWPE:TB:Sampler','Unknown block.');
end
u = randn(1,numel(index));
assert(all(isfinite(u)),'JWPE:TB:Sampler','Nonfinite Gaussian proposal.');
proposalZ = current.z; proposalZ(index) = proposalZ(index)+u*S;
assert(all(isfinite(proposalZ)),'JWPE:TB:Sampler', ...
    'Nonfinite sampled proposal coordinate.');
[proposalPhysical,~] = tb_xform_v1('to_physical',proposalZ,data.cfg);
inside = tb_support_v1(proposalPhysical,data.cfg);
targetIncrement = 0; rawIncrement = 0; cacheHit = false; cacheKey = '';
proposal = current; proposal.logTarget = -Inf;
if inside
    targetIncrement = 1;
    if blockName=="MECHANISTIC"
        prediction = tb_predict_v1(proposalPhysical(1:5),data);
        rawIncrement = prediction.rawIncrement;
        cacheHit = prediction.cacheHit; cacheKey = prediction.key;
        evaluated = tb_like_v1(proposalZ,prediction.prediction,data.ctx,data.cfg);
        proposal = evaluated; proposal.prediction = prediction.prediction;
        proposal.cacheKey = prediction.key;
    else
        evaluated = tb_like_v1(proposalZ,current.prediction,data.ctx,data.cfg);
        proposal = evaluated; proposal.prediction = current.prediction;
        proposal.cacheKey = current.cacheKey;
        cacheKey = current.cacheKey;
    end
end
if inside
    difference = proposal.logTarget-current.logTarget;
    if difference>=0, alpha = 1; else, alpha = exp(difference); end
else
    alpha = 0;
end
assert(isfinite(alpha) && alpha>=0 && alpha<=1,'JWPE:TB:Sampler', ...
    'Invalid stable acceptance probability.');
[accepted,~] = tb_accept_v1(alpha);
proposalJump2 = sum((u*S).^2);
if accepted, current = proposal; end
if accepted
    jump2 = proposalJump2;
else
    jump2 = 0;
end
if adapt, [S,~] = tb_ram_update_v1(S,u,alpha,n,data.cfg); end
record = struct('stage',char(stage),'sweep',sweep,'block',char(blockName), ...
    'supportInside',inside,'targetIncrement',targetIncrement, ...
    'rawIncrement',rawIncrement,'cacheHit',cacheHit,'accepted',accepted, ...
    'alpha',alpha,'logTarget',current.logTarget,'cacheKey',cacheKey);
if blockName=="ERROR"
    assert(rawIncrement==0,'JWPE:TB:Budget','Error-block raw forward detected.');
end
end
