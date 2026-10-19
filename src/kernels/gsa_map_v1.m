function [native,inverse] = gsa_map_v1(sample)
%GSA_MAP_V1 Map [Kd,kSigma,Fdir,kG,tinf,Ai] to native coordinates.

sample = double(sample);
assert(size(sample,2)==6 && all(isfinite(sample),'all'), ...
    'Expected finite [Kd,kSigma,Fdir,kG,tinf,Ai] rows.');
kSigma = sample(:,2);
Fdir = sample(:,3);
assert(all(kSigma>0),'kSigma must be positive.');
assert(all(Fdir>=0 & Fdir<=1),'Fdir must lie in [0,1].');
kb = kSigma.*Fdir;
krev = kSigma.*(1-Fdir);
native = [sample(:,1),kb,krev,sample(:,4:6)];

sumBack = native(:,2)+native(:,3);
inverse = [native(:,1),sumBack,native(:,2)./sumBack,native(:,4:6)];
scale = max(1,abs(sample));
assert(all(abs(inverse-sample)<=32*eps(scale),'all'), ...
    'Native mapping round-trip failed.');
end
