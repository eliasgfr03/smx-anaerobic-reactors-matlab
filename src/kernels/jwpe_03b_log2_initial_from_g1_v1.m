function x0 = jwpe_03b_log2_initial_from_g1_v1(g1,cfg)
%JWPE_03B_LOG2_INITIAL_FROM_G1_V1 Map the accepted G1 curve to a LOG2 start.
%
% t50 is the G1 time at A=0.5 over the Phase-I/II horizon. kA is chosen so
% the LOG2 derivative kA/4 at t50 matches the local G1 slope. This mapping is
% only an informed initial point; it is evaluated inside the frozen 50-call

theta=double(g1.thetaNative(:).');
assert(numel(theta)==6,'G1 reference theta must have six native parameters.');
p=JWPE_parameter_struct(jwpe_inf_native_to_engine(theta));
t=linspace(0,94,18801); A=JWPE_activity_G1(t,p);
idx=find(A>=0.5,1,'first');
if isempty(idx)
    [~,idx]=min(abs(A-0.5)); t50=t(idx);
elseif idx==1
    t50=t(1);
else
    t50=interp1(A(idx-1:idx),t(idx-1:idx),0.5,'linear');
end
h=1e-3;
slope=(JWPE_activity_G1(t50+h,p)-JWPE_activity_G1(max(0,t50-h),p)) / ...
    (t50+h-max(0,t50-h));
kA=4*max(slope,eps);

b=cfg.LOG2.bounds;
kA=min(max(kA,b(4,1)),b(4,2));
t50=min(max(t50,b(5,1)),b(5,2));
x0=[theta(1:3) kA t50];
end
