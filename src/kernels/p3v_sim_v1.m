function out = p3v_sim_v1(ctx,theta,cfg)
%P3V_SIM_V1 Run unchanged M1 prefix and task-local phase-3 continuation.

base=m1_cfg_v1();
assert(base.horizon.max_d==cfg.prefixEnd_d && ...
    isequal(base.horizon.switch_d,[49 94]),'JWPE:P3V:Horizon', ...
    'Accepted M1 prefix horizon changed.');
if strcmp(ctx.reactor,'CS')
    prefix=m1_cs_sim_v1(ctx,theta,base);
    out=local_cs(prefix,ctx,cfg);
else
    prefix=m1_pf_sim_v1(ctx,theta,base);
    out=local_pf(prefix,ctx,cfg);
end
assert(out.times_d(1)==0 && out.times_d(end)==cfg.horizon_d && ...
    all(isfinite(out.Cout_SMX)) && all(isfinite(out.terminalState)), ...
    'JWPE:P3V:Forward','Invalid full-history M1 response.');
end

function out=local_cs(prefix,ctx,cfg)
settings=ctx.settings; phase3=p3v_cont_v1('phase3','CS',settings);
y=p3v_cont_v1('remap',prefix.SMX(end,1:2).',2,3);
times=ctx.fullTimes_d(:); after=times>cfg.prefixEnd_d;
cout=zeros(numel(times),1); state=zeros(numel(times),3);
prefixIndex=times<=cfg.prefixEnd_d;
assert(isequal(times(prefixIndex),prefix.times_d),'JWPE:P3V:Prefix', ...
    'CS full and prefix grids do not align.');
cout(prefixIndex)=prefix.Cout_SMX; state(prefixIndex,:)=prefix.SMX;
breaks=unique([cfg.prefixEnd_d;ctx.forcingData.Time_d( ...
    ctx.forcingData.Time_d>cfg.prefixEnd_d);times(after);cfg.horizon_d]);
opts=odeset('RelTol',settings.RelTol,'AbsTol',settings.AbsTol);
minimum=prefix.minSMX; tol=1e-10;
for k=1:numel(breaks)-1
    t0=breaks(k); t1=breaks(k+1);
    cin=JWPE_next_zoh_influent(t0,ctx.forcingData);
    rhs=@(t,z)m1_cs_rhs_v1(t,z,cin,phase3.N,phase3.tm_d,prefix.R, ...
        prefix.p,settings);
    sol=ode15s(rhs,[t0 t1],y,opts); y=sol.y(:,end);
    minimum=min(minimum,min(sol.y,[],'all'));
    hit=find(times>t0+tol & times<=t1+tol);
    if ~isempty(hit)
        values=deval(sol,times(hit)); state(hit,:)=values.';
        cout(hit)=values(end,:).';
    end
end
assert(all(after==any(state~=0,2) | ~after),'JWPE:P3V:Forward', ...
    'Incomplete CS continuation state.');
out=struct('reactor','CS','times_d',times,'Cout_SMX',cout, ...
    'terminalState',y,'minSMX',minimum,'stateDimension',3, ...
    'phase3',phase3,'prefix',prefix);
end

function out=local_pf(prefix,ctx,cfg)
settings=ctx.settings; phase3=p3v_cont_v1('phase3','PF',settings);
y=prefix.SMX(end,:).';
assert(numel(y)==69 && phase3.N==69,'JWPE:P3V:Dimension', ...
    'PF day-94 state must have 69 components.');
times=ctx.fullTimes_d(:);
cout=zeros(numel(times),1); state=zeros(numel(times),69);
prefixIndex=times<=cfg.prefixEnd_d;
assert(isequal(times(prefixIndex),prefix.times_d),'JWPE:P3V:Prefix', ...
    'PF full and prefix grids do not align.');
cout(prefixIndex)=prefix.Cout_SMX; state(prefixIndex,:)=prefix.SMX;
breaks=unique([cfg.prefixEnd_d;ctx.forcingData.Time_d( ...
    ctx.forcingData.Time_d>cfg.prefixEnd_d);cfg.horizon_d]);
pattern=m1_pf_jpat_v1(settings);
opts=odeset('RelTol',settings.RelTol,'AbsTol',settings.AbsTol,'JPattern',pattern);
minimum=prefix.minSMX; tol=1e-10;
for k=1:numel(breaks)-1
    t0=breaks(k); t1=breaks(k+1);
    cin=JWPE_next_zoh_influent(t0,ctx.forcingData);
    rhs=@(t,z)m1_pf_rhs_v1(t,z,cin,phase3.Dax,phase3.v,prefix.R, ...
        prefix.p,settings);
    sol=ode15s(rhs,[t0 t1],y,opts); y=sol.y(:,end);
    minimum=min(minimum,min(sol.y,[],'all'));
    hit=find(times>t0+tol & times<=t1+tol);
    if ~isempty(hit)
        values=deval(sol,times(hit)); state(hit,:)=values.';
        cout(hit)=values(end,:).';
    end
end
assert(minimum>=-2*settings.AbsTol && all(isfinite(state),'all'), ...
    'JWPE:P3V:Forward','PF negative-state or finite-state guard failed.');
out=struct('reactor','PF','times_d',times,'Cout_SMX',cout, ...
    'terminalState',y,'minSMX',minimum,'stateDimension',69, ...
    'phase3',phase3,'prefix',prefix);
end
