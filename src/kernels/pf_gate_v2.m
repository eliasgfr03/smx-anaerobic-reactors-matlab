function allowed = pf_gate_v2(classification,phase,cfg)

classification = upper(string(classification));
phase = upper(string(phase));
isInvalid = classification==upper(string(cfg.invalid.classification));
if ~isInvalid
    allowed = true;
    return
end
assert(phase=="OPT",'JWPE:PFAP2:InvalidState', ...
    'INVALID_ENDPOINT_RECHECK_OR_CLOSURE_STOP');
allowed = true;
end
