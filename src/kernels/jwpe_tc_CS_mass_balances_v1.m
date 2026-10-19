function dydt = jwpe_tc_CS_mass_balances_v1(t,y,Cin,N,tm_d,R,p,settings,activityFcn)
%JWPE_TC_CS_MASS_BALANCES_V1 CS balances with modular transient capacity.
%
% This is equation-equivalent to validated CS_mass_balances except that A(t)
% is received through a function handle. No hydraulic/storage term changes.

SMX=y(1:2:end); TP=y(2:2:end);
A=activityFcn(t);
rate=settings.XVSS_g_L.*A.*(p.kb.*SMX-p.krev.*TP);
h=N/(tm_d*R);
SMX_in=[Cin;SMX(1:end-1)]; TP_in=[0;TP(1:end-1)];
dSMX=h.*(SMX_in-SMX)-rate; dTP=h.*(TP_in-TP)+rate;
dydt=zeros(size(y)); dydt(1:2:end)=dSMX; dydt(2:2:end)=dTP;
end
