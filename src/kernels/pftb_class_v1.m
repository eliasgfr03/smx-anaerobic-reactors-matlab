function out = pftb_class_v1(action,value,cfg)
%PFTB_CLASS_V1 Pure support/forward-result/failure classification.

action = lower(string(action));
switch action
    case "support"
        physical = double(value(:).');
        inside = tb_support_v1(physical,cfg);
        out = struct('classification',local_if(inside, ...
            'WITHIN_HARD_SUPPORT','FINITE_SUPPORT_REJECTION'), ...
            'inside',inside,'targetIncrement',0,'rawIncrement',0, ...
            'retry',false,'stop',false);
    case "minimum"
        minimum = double(value);
        assert(isscalar(minimum) && isfinite(minimum), ...
            'JWPE:PFTB:ForwardFailure','Invalid PF minimum.');
        invalid = minimum<cfg.invalid.threshold;
        out = struct('classification',local_if(invalid, ...
            cfg.invalid.classification,'FINITE_STATE_WITHIN_TOLERANCE'), ...
            'inside',true,'invalid',invalid,'targetIncrement',1, ...
            'rawIncrement',1,'retry',false,'stop',false);
    case "exception"
        identifier = string(value);
        known = identifier=="JWPE:PFTB:DeterministicInvalid";
        out = struct('classification',local_if(known, ...
            cfg.invalid.classification,'UNKNOWN_NUMERICAL_FAILURE_STOP'), ...
            'inside',true,'invalid',known,'targetIncrement',1, ...
            'rawIncrement',double(known),'retry',false,'stop',~known);
    otherwise
        error('JWPE:PFTB:Classification','Unsupported classification action.');
end
end

function value = local_if(test,a,b)
if test, value = a; else, value = b; end
end

