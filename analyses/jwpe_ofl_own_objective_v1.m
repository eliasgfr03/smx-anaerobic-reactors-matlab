function value=jwpe_ofl_own_objective_v1(z)
%JWPE_OFL_OWN_OBJECTIVE_V1 Named callback without captured workspace.
s=jwpe_ofl_own_state_v1('get');
assert(s.calls(s.block)<s.caps(s.block),'JWPE:Own:OFLCallCap','Objective cap reached.');
s.calls(s.block)=s.calls(s.block)+1;jwpe_ofl_own_state_v1('put',s);
e=jwpe_ofl_own_evaluate_v1(z,false);value=e.fit.nll;
end
