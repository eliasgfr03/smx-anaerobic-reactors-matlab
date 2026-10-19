function theta = jwpe_s04_full_theta_v2(profileIdx,fixedValue,nuisance)
%JWPE_S04_FULL_THETA_V2 Reconstruct [Kd kb krev kG tinf Ai].
validateattributes(profileIdx,{'numeric'},{'scalar','integer','>=',1,'<=',6});
nuisance=double(nuisance(:).');
assert(numel(nuisance)==5,'Expected five nuisance parameters.');
theta=nan(1,6); theta(profileIdx)=double(fixedValue);
freeIdx=setdiff(1:6,profileIdx,'stable'); theta(freeIdx)=nuisance;
end
