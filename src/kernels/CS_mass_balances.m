function dydt = CS_mass_balances(t,y,Cin,N,tm_d,R,p,settings)
%CS_MASS_BALANCES Aqueous SMX/TP balances in the conceptual TIS compartments.
%
% State ordering:
%   y = [SMX_1, TP_1, SMX_2, TP_2, ...]'
%
% Only aqueous material transfers hydraulically between conceptual tanks.
% Solid-associated material is represented through the equilibrium storage
% factor R = 1 + Kd*XTSS and does not wash out independently.

SMX = y(1:2:end);
TP  = y(2:2:end);

%% Reversible kinetic term
A = JWPE_activity_G1(t,p);
rate = settings.XVSS_g_L .* A .* (p.kb.*SMX - p.krev.*TP);

%% Hydraulic exchange coefficient
h = N/(tm_d*R);
SMX_in = [Cin; SMX(1:end-1)];
TP_in  = [0;   TP(1:end-1)];

%% Balances
dSMX = h.*(SMX_in-SMX) - rate;
dTP  = h.*(TP_in-TP) + rate;

dydt = zeros(size(y));
dydt(1:2:end) = dSMX;
dydt(2:2:end) = dTP;
end
