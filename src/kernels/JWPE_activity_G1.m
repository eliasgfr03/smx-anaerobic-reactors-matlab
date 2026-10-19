function A = JWPE_activity_G1(t,p)
% Normalized Gompertz G1; p fields kG, tinf, Ai. Exactly A(0)=Ai.
g0=exp(-exp(p.kG*p.tinf)); g=exp(-exp(-p.kG*(t-p.tinf))); A=p.Ai+(1-p.Ai).*(g-g0)./(1-g0);
end
