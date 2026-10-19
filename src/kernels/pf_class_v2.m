function out = pf_class_v2(info,cfg,phase)
%PF_CLASS_V2 Pure approved PF-v2 negative-state classification.

phase = upper(string(phase));
required = {'minimum','segmentIndex','phase','time_d','nodeIndex', ...
    'solver','reportedMinimum','agreementDelta','agreementTolerance'};
assert(isstruct(info) && all(isfield(info,required)) && ...
    isfinite(info.minimum),'JWPE:PFAP2:InvalidState', ...
    'Invalid minimum-location evidence.');
isInvalid = info.minimum<cfg.invalid.threshold;
out = info;
out.invalid = isInvalid;
out.eligible = ~isInvalid;
out.nll = NaN;
out.rawForwardIncrement = double(isInvalid);
out.optimizerCallIncrement = double(phase=="OPT");
out.sigmaProfiled = false;
out.cacheWritten = false;
out.retry = false;
if isInvalid
    out.classification = cfg.invalid.classification;
else
    out.classification = 'FINITE_STATE_WITHIN_TOLERANCE';
end
if isInvalid
    assert(phase=="OPT",'JWPE:PFAP2:InvalidState', ...
        'INVALID_ENDPOINT_RECHECK_OR_CLOSURE_STOP');
end
end
