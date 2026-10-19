function dydt = jwpe_tc_PF_mass_balances_v1(t,y,Cin,Dax,v,R,p,settings,activityFcn)
%JWPE_TC_PF_MASS_BALANCES_V1 PF balances with modular transient capacity.
%
% Transport remains the validated TVD/MUSCL MINMOD + second-order dispersion
% formulation. Only the scalar activity/capacity multiplier is modularized.

n=settings.node_count; ni=n-2;
SMX=zeros(n,1); TP=zeros(n,1);
SMX(1)=Cin; TP(1)=0;
SMX(2:end-1)=y(1:ni); TP(2:end-1)=y(ni+1:end);
SMX(end)=SMX(end-1); TP(end)=TP(end-1);
SMX_z=PF_minmod_derivative(SMX,settings.dz);
TP_z=PF_minmod_derivative(TP,settings.dz);
SMX_zz=PF_second_order_dispersion(SMX,settings.dz);
TP_zz=PF_second_order_dispersion(TP,settings.dz);
A=activityFcn(t);
rate=settings.XVSS_g_L.*A.*(p.kb.*SMX-p.krev.*TP);
transportSMX=(-v.*SMX_z(2:end-1)+Dax.*SMX_zz(2:end-1))/R;
transportTP=(-v.*TP_z(2:end-1)+Dax.*TP_zz(2:end-1))/R;
dydt=zeros(2*ni,1);
dydt(1:ni)=transportSMX-rate(2:end-1);
dydt(ni+1:end)=transportTP+rate(2:end-1);
end
