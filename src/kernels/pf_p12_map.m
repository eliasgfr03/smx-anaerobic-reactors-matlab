function [theta,z] = pf_p12_map(x,S)
%PF_PL_MAP Map stage nuisance coordinates to native theta and derived search z.
x=double(x(:).'); assert(numel(x)==S.nvar); v=struct();
for i=1:S.nvar; v.(char(S.names(i)))=x(i); end
p=S.param; fv=S.fixedValue;
if p=="krev"
    ks=S.fixedKsigma; if isnan(ks); ks=v.kSigma; end
    z=[v.Kd,ks,1-fv/ks,v.kG,v.tinf,v.Ai]; theta=[v.Kd,ks-fv,fv,v.kG,v.tinf,v.Ai];
elseif p=="kb"
    ks=S.fixedKsigma; if isnan(ks); ks=v.kSigma; end
    z=[v.Kd,ks,fv/ks,v.kG,v.tinf,v.Ai]; theta=[v.Kd,fv,ks-fv,v.kG,v.tinf,v.Ai];
else
    if p=="Kd"; Kd=fv; else; Kd=v.Kd; end
    if p=="kG"; kG=fv; else; kG=v.kG; end
    if p=="tinf"; tinf=fv; else; tinf=v.tinf; end
    if p=="Ai"; Ai=fv; else; Ai=v.Ai; end
    ks=v.kSigma; fd=v.Fdir; z=[Kd,ks,fd,kG,tinf,Ai];
    theta=[Kd,ks*fd,ks*(1-fd),kG,tinf,Ai];
end
end
