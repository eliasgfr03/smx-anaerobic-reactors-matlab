function out = m1_cs_sim_v1(ctx,thetaM1,cfg)
%M1_CS_SIM_V1 Simulate the reduced irreversible CS model through day 94.

assert(strcmp(ctx.reactor,'CS'),'JWPE:M1:Config','CS context required.');
map = m1_map_v1(thetaM1,cfg);
p = JWPE_parameter_struct(map.thetaEngine);
settings = ctx.settings;
R = 1+p.Kd*settings.XTSS_g_L;
times = ctx.auditTimes_d(:);
assert(times(1)==0 && times(end)==94 && ~any(times>94), ...
    'JWPE:M1:Horizon','Invalid CS audit horizon.');
breaks = unique([0;ctx.forcingData.Time_d;times;settings.switch_days(:)]);
breaks = breaks(breaks>=0 & breaks<=cfg.horizon.max_d);

N = settings.tanks_in_series(1);
y = zeros(N,1);
state = zeros(numel(times),3);
activeN = zeros(numel(times),1);
phaseAt = zeros(numel(times),1);
Cout = zeros(numel(times),1);
activeN(1) = N;
phaseAt(1) = 1;
segments = repmat(local_empty_segment(),numel(breaks)-1,1);
minState = 0;
maxState = 0;
opts = odeset('RelTol',settings.RelTol,'AbsTol',settings.AbsTol);
tol = 1e-10;
for k=1:numel(breaks)-1
    t0 = breaks(k);
    t1 = breaks(k+1);
    phase = 1+(t0>=settings.switch_days(1))+(t0>=settings.switch_days(2));
    targetN = settings.tanks_in_series(phase);
    if targetN~=N
        y = local_remap(y,N,targetN);
        N = targetN;
    end
    Cin = JWPE_next_zoh_influent(t0,ctx.forcingData);
    tm_d = settings.mean_residence_time_h(phase)/24;
    rhs = @(t,z)m1_cs_rhs_v1(t,z,Cin,N,tm_d,R,p,settings);
    sol = ode15s(rhs,[t0 t1],y,opts);
    y = sol.y(:,end);
    minState = min(minState,min(sol.y,[],'all'));
    maxState = max(maxState,max(sol.y,[],'all'));
    segments(k) = struct('t0',t0,'t1',t1,'phase',phase,'N',N, ...
        'Cin',Cin,'tm_d',tm_d,'Dax',NaN,'v',NaN,'sol',sol);
    hit = find(times>t0+tol & times<=t1+tol);
    if ~isempty(hit)
        values = deval(sol,times(hit));
        state(hit,1:N) = values.';
        activeN(hit) = N;
        phaseAt(hit) = phase;
        Cout(hit) = values(end,:).';
    end
end
assert(all(activeN>0) && all(isfinite(Cout)) && all(isfinite(state),'all'), ...
    'JWPE:M1:ForwardFailure','CS M1 returned incomplete or nonfinite values.');
out = struct('reactor','CS','model','M1','map',map,'p',p,'R',R, ...
    'times_d',times,'Cout_SMX',Cout,'SMX',state,'activeN',activeN, ...
    'phase',phaseAt,'segments',segments,'minSMX',minState, ...
    'maxSMX',maxState,'stateDimensionMax',3,'stateDimensionIntegrated', ...
    unique(activeN).');
end

function yNew = local_remap(yOld,oldN,newN)
oldEdge = linspace(0,1,oldN+1);
newEdge = linspace(0,1,newN+1);
yNew = zeros(newN,1);
for j=1:newN
    for k=1:oldN
        overlap = max(0,min(newEdge(j+1),oldEdge(k+1))- ...
            max(newEdge(j),oldEdge(k)));
        yNew(j) = yNew(j)+overlap*yOld(k)/(newEdge(j+1)-newEdge(j));
    end
end
end

function s = local_empty_segment()
s = struct('t0',NaN,'t1',NaN,'phase',NaN,'N',NaN,'Cin',NaN, ...
    'tm_d',NaN,'Dax',NaN,'v',NaN,'sol',struct());
end

