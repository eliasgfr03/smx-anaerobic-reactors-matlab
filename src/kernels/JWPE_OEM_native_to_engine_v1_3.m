function [thetaEngine,derived] = JWPE_OEM_native_to_engine_v1_3(thetaNative)
%JWPE_OEM_NATIVE_TO_ENGINE_V1_3 Map native reversible coordinates to engine.
% Native order: [Kd,kb,krev,kG,tinf,Ai]
% Engine order: [Kd,kSigma,Fdir,kG,tinf,Ai]

thetaNative = thetaNative(:).';
assert(numel(thetaNative)==6, ...
    'Expected [Kd,kb,krev,kG,tinf,Ai].');
Kd=thetaNative(1); kb=thetaNative(2); krev=thetaNative(3);
kG=thetaNative(4); tinf=thetaNative(5); Ai=thetaNative(6);
kSigma=kb+krev;
assert(isfinite(kSigma) && kSigma>0, ...
    'kb+krev must be finite and strictly positive.');
Fdir=kb/kSigma;
thetaEngine=[Kd,kSigma,Fdir,kG,tinf,Ai];
derived=struct('kSigma',kSigma,'Fdir',Fdir,'kb',kb,'krev',krev);
end
