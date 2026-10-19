function [theta,z] = plr11_map(x,S)
%PLR11_MAP Map nuisance coordinates to native theta and engine search coordinates.
x=double(x(:).'); assert(numel(x)==S.nvar); v=struct();
for i=1:S.nvar; v.(char(S.names(i)))=x(i); end
if S.param=="Kd"
    ks=v.kSigma; fd=v.Fdir; theta=[S.fixedValue,ks*fd,ks*(1-fd),v.kG,v.tinf,v.Ai];
    z=[S.fixedValue,ks,fd,v.kG,v.tinf,v.Ai];
elseif S.param=="kb"
    ks=v.kSigma; theta=[v.Kd,S.fixedValue,ks-S.fixedValue,v.kG,v.tinf,v.Ai];
    z=[v.Kd,ks,S.fixedValue/ks,v.kG,v.tinf,v.Ai];
else
    error('Unsupported R1.1 profile parameter.');
end
end
