function [theta,z] = plr1_map(x,S)
%PLR1_MAP Map nuisance coordinates to native theta and engine search coordinates.
x=double(x(:).'); v=struct(); for i=1:S.nvar; v.(char(S.names(i)))=x(i); end; p=S.param; fv=S.fixedValue;
if p=="krev"
 ks=v.kSigma; z=[v.Kd,ks,1-fv/ks,v.kG,v.tinf,v.Ai]; theta=[v.Kd,ks-fv,fv,v.kG,v.tinf,v.Ai];
else
 if p=="Kd"; Kd=fv; else; Kd=v.Kd; end; if p=="Ai"; Ai=fv; else; Ai=v.Ai; end
 ks=v.kSigma; fd=v.Fdir; z=[Kd,ks,fd,v.kG,v.tinf,Ai]; theta=[Kd,ks*fd,ks*(1-fd),v.kG,v.tinf,Ai];
end
end
