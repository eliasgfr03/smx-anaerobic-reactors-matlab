function dydt = m1_cs_rhs_v1(t,y,Cin,N,tm_d,R,p,settings)
%M1_CS_RHS_V1 Irreversible parent-SMX TIS balance for active CS tanks.

y = y(:);
assert(numel(y)==N && any(N==[2 3]),'JWPE:M1:Dimension', ...
    'CS active state must contain two or three SMX tanks.');
A = JWPE_activity_G1(t,p);
rate = settings.XVSS_g_L.*A.*p.kb.*y;
h = N/(tm_d*R);
upstream = [Cin;y(1:end-1)];
dydt = h.*(upstream-y)-rate;
end

