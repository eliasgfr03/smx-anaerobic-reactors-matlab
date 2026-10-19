function [thetaEngine,derived] = jwpe_inf_native_to_engine(thetaNative)
%JWPE_INF_NATIVE_TO_ENGINE Convert native reversible coordinates to engine form.
%
% INPUT  thetaNative = [Kd, kb, krev, kG, tinf, Ai]
% OUTPUT thetaEngine = [Kd, kSigma, Fdir, kG, tinf, Ai]
%
% This adapter is algebra only. It does not modify the validated CS/PF engine.
% Keeping this conversion in one shared function prevents future PL/MCMC code
% from silently mixing the two parameterizations.

thetaNative = thetaNative(:).';
assert(numel(thetaNative)==6, ...
    'Expected thetaNative = [Kd,kb,krev,kG,tinf,Ai].');
assert(all(isfinite(thetaNative)), 'Native parameters must be finite.');

Kd = thetaNative(1);
kb = thetaNative(2);
krev = thetaNative(3);
kG = thetaNative(4);
tinf = thetaNative(5);
Ai = thetaNative(6);

kSigma = kb + krev;
assert(kSigma>0, 'kb+krev must be positive.');
Fdir = kb/kSigma;

thetaEngine = [Kd,kSigma,Fdir,kG,tinf,Ai];
derived = struct('kSigma',kSigma,'Fdir',Fdir);
end
