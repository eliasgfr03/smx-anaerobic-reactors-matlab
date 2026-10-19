function p = JWPE_parameter_struct(theta)
% theta order: [Kd kSigma Fdir kG tinf Ai]
assert(numel(theta)==6,'Expected six parameters [Kd kSigma Fdir kG tinf Ai].'); theta=theta(:)';
p=struct('Kd',theta(1),'kSigma',theta(2),'Fdir',theta(3),'kG',theta(4),'tinf',theta(5),'Ai',theta(6));
p.kb=p.Fdir*p.kSigma; p.krev=(1-p.Fdir)*p.kSigma;
end
