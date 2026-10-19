function thetaNative = jwpe_inf_engine_to_native(thetaEngine)
%JWPE_INF_ENGINE_TO_NATIVE Convert validated-engine coordinates to native form.
%
% INPUT  thetaEngine = [Kd, kSigma, Fdir, kG, tinf, Ai]
% OUTPUT thetaNative = [Kd, kb, krev, kG, tinf, Ai]

thetaEngine = thetaEngine(:).';
assert(numel(thetaEngine)==6, ...
    'Expected thetaEngine = [Kd,kSigma,Fdir,kG,tinf,Ai].');
assert(all(isfinite(thetaEngine)), 'Engine parameters must be finite.');

Kd = thetaEngine(1);
kSigma = thetaEngine(2);
Fdir = thetaEngine(3);
kG = thetaEngine(4);
tinf = thetaEngine(5);
Ai = thetaEngine(6);
assert(kSigma>0, 'kSigma must be positive.');
assert(Fdir>=0 && Fdir<=1, 'Fdir must lie in [0,1].');

kb = kSigma*Fdir;
krev = kSigma*(1-Fdir);
thetaNative = [Kd,kb,krev,kG,tinf,Ai];
end
