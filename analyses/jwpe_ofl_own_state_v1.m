function out=jwpe_ofl_own_state_v1(action,value)
%JWPE_OFL_OWN_STATE_V1 Process-local state for named noncapturing callbacks.
persistent state
switch action
    case 'put'
        state=value;out=[];
    case 'get'
        assert(~isempty(state),'JWPE:Own:Registry','OFL state not initialized.');out=state;
    case 'clear'
        state=[];out=[];
    otherwise
        error('JWPE:Own:Registry','Unknown registry operation.');
end
end
