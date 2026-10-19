function [thetaNative,derived] = JWPE_OEM_engine_to_native_v1_3(thetaEngine)
%JWPE_OEM_ENGINE_TO_NATIVE_V1_3 Map historical engine coordinates to native.
% Engine order: [Kd,kSigma,Fdir,kG,tinf,Ai]
% Native order: [Kd,kb,krev,kG,tinf,Ai]

thetaEngine = thetaEngine(:).';
assert(numel(thetaEngine)==6, ...
    'Expected [Kd,kSigma,Fdir,kG,tinf,Ai].');
Kd=thetaEngine(1); kSigma=thetaEngine(2); Fdir=thetaEngine(3);
kG=thetaEngine(4); tinf=thetaEngine(5); Ai=thetaEngine(6);
assert(isfinite(kSigma) && kSigma>0, ...
    'kSigma must be finite and strictly positive.');
assert(isfinite(Fdir) && Fdir>=0 && Fdir<=1, ...
    'Fdir must be finite and lie in [0,1].');
kb=Fdir*kSigma;
krev=(1-Fdir)*kSigma;
thetaNative=[Kd,kb,krev,kG,tinf,Ai];
derived=struct('kSigma',kSigma,'Fdir',Fdir,'kb',kb,'krev',krev);
end
