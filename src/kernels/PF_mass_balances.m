function dydt = PF_mass_balances(t,y,Cin,Dax,v,R,p,settings)
%PF_MASS_BALANCES Semi-discrete PF-AnFBR aqueous SMX/TP balances.
%
% Reduced state: only the 69 interior/differential nodes of each aqueous
% species are integrated (138 ODE states total). Boundary values are rebuilt:
%   inlet:  SMX = Cin, TP = 0
%   outlet: zero axial gradient, C_n = C_(n-1)
%
% The kinetic reaction is evaluated across every interior computational node,
% matching the final GSA implementation over the full 0.84-m domain.

n = settings.node_count;
ni = n-2;

%% Rebuild full profiles including boundary values
SMX = zeros(n,1);
TP  = zeros(n,1);
SMX(1) = Cin;
TP(1) = 0;
SMX(2:end-1) = y(1:ni);
TP(2:end-1)  = y(ni+1:end);
SMX(end) = SMX(end-1);
TP(end)  = TP(end-1);

%% Transport derivatives
SMX_z  = PF_minmod_derivative(SMX,settings.dz);
TP_z   = PF_minmod_derivative(TP,settings.dz);
SMX_zz = PF_second_order_dispersion(SMX,settings.dz);
TP_zz  = PF_second_order_dispersion(TP,settings.dz);

%% Reversible kinetic term
A = JWPE_activity_G1(t,p);
rate = settings.XVSS_g_L .* A .* (p.kb.*SMX - p.krev.*TP);

%% Interior balances
transportSMX = (-v.*SMX_z(2:end-1) + Dax.*SMX_zz(2:end-1))/R;
transportTP  = (-v.*TP_z(2:end-1)  + Dax.*TP_zz(2:end-1))/R;

dydt = zeros(2*ni,1);
dydt(1:ni)     = transportSMX - rate(2:end-1);
dydt(ni+1:end) = transportTP  + rate(2:end-1);
end
