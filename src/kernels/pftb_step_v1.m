function [current,S,record,jump2] = pftb_step_v1( ...
        current,blockName,S,adapt,n,data,stage,sweep,segmentId)
%PFTB_STEP_V1 One approved symmetric two-block proposal.

blockName = upper(string(blockName));
if blockName=="MECHANISTIC", index = data.cfg.blocks.mechanistic;
elseif blockName=="ERROR", index = data.cfg.blocks.error;
else, error('JWPE:PFTB:Sampler','Unknown proposal block.');
end
u = randn(1,numel(index)); proposalZ = current.z;
proposalZ(index) = proposalZ(index)+u*S;
assert(all(isfinite(proposalZ)),'JWPE:PFTB:Sampler', ...
    'Nonfinite sampled proposal.');
physical = tb_xform_v1('to_physical',proposalZ,data.cfg);
support = pftb_class_v1('support',physical,data.cfg);
targetIncrement = 0; rawIncrement = 0; cacheHit = false;
classification = support.classification; proposal = current;
proposal.logTarget = -Inf; predictionKey = ""; targetKey = "";
forwardElapsed = 0;
if support.inside
    targetIncrement = 1;
    if blockName=="MECHANISTIC"
        prediction = pftb_predict_v1(physical(1:5),data);
        rawIncrement = prediction.rawIncrement;
        forwardElapsed = prediction.elapsed_s;
        cacheHit = prediction.cacheHit; predictionKey = string(prediction.key);
        classification = prediction.classification;
        if prediction.valid
            proposal = pftb_like_v1(proposalZ,prediction.prediction,data);
            proposal.predictionKey = prediction.key;
            targetKey = string(proposal.targetKey);
        end
    else
        proposal = pftb_like_v1(proposalZ,current.prediction,data);
        proposal.predictionKey = current.predictionKey;
        classification = 'FINITE_TARGET';
        targetKey = string(proposal.targetKey);
    end
end
if isfinite(proposal.logTarget)
    difference = proposal.logTarget-current.logTarget;
    if difference>=0, alpha = 1; else, alpha = exp(difference); end
else
    alpha = 0;
end
assert(isfinite(alpha) && alpha>=0 && alpha<=1, ...
    'JWPE:PFTB:Sampler','Invalid acceptance probability.');
[accepted,~] = tb_accept_v1(alpha);
proposalJump2 = sum((u*S).^2);
if accepted, current = proposal; jump2 = proposalJump2; else, jump2 = 0; end
if adapt, [S,~] = tb_ram_update_v1(S,u,alpha,n,data.cfg); end
record = struct('stage',char(stage),'segmentId',segmentId,'sweep',sweep, ...
    'block',char(blockName),'classification',classification, ...
    'supportInside',support.inside,'targetIncrement',targetIncrement, ...
    'rawIncrement',rawIncrement,'cacheHit',cacheHit,'accepted',accepted, ...
    'alpha',alpha,'logTarget',current.logTarget, ...
    'predictionKey',char(predictionKey),'targetKey',char(targetKey), ...
    'forwardElapsed_s',forwardElapsed);
if blockName=="ERROR"
    assert(rawIncrement==0,'JWPE:PFTB:Budget', ...
        'Error-block raw forward detected.');
end
end
