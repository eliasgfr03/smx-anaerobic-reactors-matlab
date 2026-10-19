function map = m1_map_v1(thetaM1,cfg)
%M1_MAP_V1 Map [Kd,kb,kG,tinf,Ai] to native and engine coordinates.

if nargin<2
    cfg = m1_cfg_v1();
end
thetaM1 = double(thetaM1(:).');
assert(numel(thetaM1)==5 && all(isfinite(thetaM1)), ...
    'JWPE:M1:Mapping','Expected finite [Kd,kb,kG,tinf,Ai].');
assert(thetaM1(1)>=0 && thetaM1(2)>=0 && thetaM1(3)>0 && ...
    thetaM1(4)>=0 && thetaM1(5)>=0 && thetaM1(5)<=1, ...
    'JWPE:M1:Mapping','Invalid M1 coordinates.');
native = [thetaM1(1:2),0,thetaM1(3:5)];
engine = [thetaM1(1),thetaM1(2),1,thetaM1(3:5)];
if thetaM1(2)==0
    % Approved M1 boundary convention: kSigma=0 and Fdir=1.
    shared = engine;
else
    shared = jwpe_inf_native_to_engine(native);
end
err = max(abs(engine-shared));
assert(err<=cfg.tolerance.mapping,'JWPE:M1:Mapping', ...
    'M1/native/engine mapping error %.17g exceeds tolerance.',err);
map = struct('thetaM1',thetaM1,'thetaNative',native, ...
    'thetaEngine',engine,'krev',0,'kSigma',thetaM1(2),'Fdir',1, ...
    'maxAbsError',err);
end
