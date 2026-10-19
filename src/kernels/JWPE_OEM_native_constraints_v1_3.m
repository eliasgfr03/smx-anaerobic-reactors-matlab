function [A,b,meta] = JWPE_OEM_native_constraints_v1_3(cfg,spec)
%JWPE_OEM_NATIVE_CONSTRAINTS_V1_3 Exact historical-support image in native coordinates.
%
% Physical native constraints:
%   kSigmaMin <= kb+krev <= kSigmaMax
%   kb/(kb+krev) >= FdirMin
% With kb+krev>0, the last condition is linear:
%   -(1-FdirMin)*kb + FdirMin*krev <= 0.
%
% fmincon operates here on normalized coordinates u in [0,1], with
% x = xLB + u.*(xUB-xLB), where x includes native mean parameters followed
% by log(error parameters). This function maps the physical linear
% constraints exactly to A*u <= b.

meanLB=cfg.meanBounds(:,1);
meanUB=cfg.meanBounds(:,2);
errLB=spec.errorBounds(:,1);
errUB=spec.errorBounds(:,2);
xLB=[meanLB;log(errLB)];
xUB=[meanUB;log(errUB)];
xRange=xUB-xLB;

n=numel(xLB);
Aphys=zeros(3,n);
bphys=zeros(3,1);
kmin=cfg.equivalentHistoricalSupport.kSigma(1);
kmax=cfg.equivalentHistoricalSupport.kSigma(2);
fmin=cfg.equivalentHistoricalSupport.Fdir(1);

% kb + krev <= kmax
Aphys(1,2)=1; Aphys(1,3)=1; bphys(1)=kmax;
% -(kb + krev) <= -kmin
Aphys(2,2)=-1; Aphys(2,3)=-1; bphys(2)=-kmin;
% -(1-fmin)*kb + fmin*krev <= 0
Aphys(3,2)=-(1-fmin); Aphys(3,3)=fmin; bphys(3)=0;

A=Aphys.*(xRange.');
b=bphys-Aphys*xLB;
meta=struct('Aphysical',Aphys,'bphysical',bphys, ...
    'xLB',xLB,'xUB',xUB,'xRange',xRange, ...
    'labels',{{'kSigma_upper','kSigma_lower','Fdir_lower'}});
end
