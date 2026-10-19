function result = jwpe_03b_log2_simulate_model_v1(reactor,mode,theta, ...
    data,settings,targetTimes,storeDetail)
%JWPE_03B_LOG2_SIMULATE_MODEL_V1 Capacity-modular Phase-I/II simulator.
%
% The validated CS/PF transport, storage, MINMOD advection, D2 dispersion,
% sparse PF JPattern and reversible mass balances are unchanged. The only
% scientific insertion point is the scalar activity law.
%
% mode G1   : theta = [Kd kb krev kG tinf Ai], used only for equivalence QA.
%
% Integration stops at max(targetTimes), so Phase III is not traversed.

if nargin<7 || isempty(storeDetail); storeDetail = false; end
reactor = upper(string(reactor)); mode = upper(string(mode));
theta = double(theta(:).'); targetTimes = unique(double(targetTimes(:)));
assert(~isempty(targetTimes),'At least one target time is required.');
assert(max(targetTimes)<=94+1e-10, ...
    'LOG2 Stage 03B must not integrate beyond Phase II (day 94).');

switch mode
    case "G1"
        assert(numel(theta)==6,'G1 expects [Kd kb krev kG tinf Ai].');
        thetaEngine = jwpe_inf_native_to_engine(theta);
        p = JWPE_parameter_struct(thetaEngine);
        activityFcn = @(t)JWPE_activity_G1(t,p);
    case "LOG2"
        assert(numel(theta)==5,'LOG2 expects [Kd kb krev kA t50].');
        p = struct('Kd',theta(1),'kb',theta(2),'krev',theta(3));
        kA=theta(4); t50=theta(5);
        activityFcn = @(t)jwpe_03b_log2_activity_v1(t,kA,t50);
    otherwise
        error('Unsupported activity mode: %s.',mode);
end
R = 1 + p.Kd*settings.XTSS_g_L;

switch reactor
    case "CS"
        result = local_cs(p,R,activityFcn,data,settings,targetTimes,storeDetail);
    case "PF"
        result = local_pf(p,R,activityFcn,data,settings,targetTimes,storeDetail);
    otherwise
        error('reactor must be CS or PF.');
end
result.mode = char(mode);
result.theta = theta;
end

function result = local_cs(p,R,activityFcn,data,settings,targetTimes,storeDetail)
endTime = max(targetTimes);
events = unique([0;data.Time_d;targetTimes;settings.switch_days(:)]);
events = events(events>=0 & events<=endTime);
N=settings.tanks_in_series(1); y=zeros(2*N,1);
prediction=nan(numel(targetTimes),1); minimumSMX=inf; minimumTP=inf;

if storeDetail %#ok<IFBDUP>
    denseT=[]; densePhase=[]; denseCin=[]; denseA=[];
    denseSMX=nan(0,3); denseTP=nan(0,3);
else
    denseT=[]; densePhase=[]; denseCin=[]; denseA=[];
    denseSMX=nan(0,3); denseTP=nan(0,3);
end
opts=odeset('RelTol',settings.RelTol,'AbsTol',settings.AbsTol);
for k=1:numel(events)-1
    t0=events(k); t1=events(k+1);
    phase=1+(t0>=settings.switch_days(1))+(t0>=settings.switch_days(2));
    targetN=settings.tanks_in_series(phase);
    if targetN~=N; y=CS_conservative_remap(y,N,targetN); N=targetN; end
    Cin=JWPE_next_zoh_influent(t0,data);
    tm_d=settings.mean_residence_time_h(phase)/24;
    rhs=@(t,z)jwpe_tc_CS_mass_balances_v1(t,z,Cin,N,tm_d,R,p,settings,activityFcn);
    if storeDetail; tspan=unique([t0:0.25:t1,t1]); else; tspan=[t0 t1]; end
    [tout,Y]=ode15s(rhs,tspan,y,opts); y=Y(end,:)';
    minimumSMX=min(minimumSMX,min(Y(:,1:2:end),[],'all'));
    minimumTP=min(minimumTP,min(Y(:,2:2:end),[],'all'));
    if storeDetail
        nt=numel(tout); addSMX=nan(nt,3); addTP=nan(nt,3);
        addSMX(:,1:N)=Y(:,1:2:end); addTP(:,1:N)=Y(:,2:2:end);
        denseT=[denseT;tout(:)]; %#ok<AGROW>
        densePhase=[densePhase;repmat(phase,nt,1)]; %#ok<AGROW>
        denseCin=[denseCin;repmat(Cin,nt,1)]; %#ok<AGROW>
        denseA=[denseA;activityFcn(tout(:))]; %#ok<AGROW>
        denseSMX=[denseSMX;addSMX]; %#ok<AGROW>
        denseTP=[denseTP;addTP]; %#ok<AGROW>
    end
    hit=find(abs(targetTimes-t1)<1e-10);
    if ~isempty(hit); prediction(hit)=y(end-1); end
end
if storeDetail
    dense=table(denseT,densePhase,denseCin,denseA, ...
        denseSMX(:,1),denseSMX(:,2),denseSMX(:,3), ...
        denseTP(:,1),denseTP(:,2),denseTP(:,3), ...
        'VariableNames',{'Time_d','Phase','Cin_ug_L','Activity', ...
        'SMX_tank_1','SMX_tank_2','SMX_tank_3', ...
        'TP_tank_1','TP_tank_2','TP_tank_3'});
else
    dense=table();
end
result=struct('parameters',p,'target_times',targetTimes, ...
    'prediction_ug_L',prediction,'R',R,'min_SMX',minimumSMX, ...
    'min_TP',minimumTP,'dense',dense);
end

function result = local_pf(p,R,activityFcn,data,settings,targetTimes,storeDetail)
ni=settings.node_count-2; y=zeros(2*ni,1); endTime=max(targetTimes);
integrationBreaks=unique([0;data.Time_d;settings.switch_days(:);endTime]);
integrationBreaks=integrationBreaks(integrationBreaks>=0 & integrationBreaks<=endTime);
prediction=nan(numel(targetTimes),1); minimumSMX=inf; minimumTP=inf;
if storeDetail %#ok<IFBDUP>
    profiles=struct('Time_d',{},'Phase',{},'SMX',{},'TP',{});
else
    profiles=struct('Time_d',{},'Phase',{},'SMX',{},'TP',{});
end
S=PF_jpattern_reduced(settings);
assert(isequal(size(S),[2*ni 2*ni]),'JPattern/state-size mismatch.');
opts=odeset('RelTol',settings.RelTol,'AbsTol',settings.AbsTol,'JPattern',S);
timeTol=1e-10;
for k=1:numel(integrationBreaks)-1
    t0=integrationBreaks(k); t1=integrationBreaks(k+1);
    phase=1+(t0>=settings.switch_days(1))+(t0>=settings.switch_days(2));
    Cin=JWPE_next_zoh_influent(t0,data);
    Dax=settings.axial_dispersion_m2_d(phase); v=settings.axial_velocity_m_d(phase);
    rhs=@(t,z)jwpe_tc_PF_mass_balances_v1(t,z,Cin,Dax,v,R,p,settings,activityFcn);
    sol=ode15s(rhs,[t0 t1],y,opts); y=sol.y(:,end);
    minimumSMX=min(minimumSMX,min(sol.y(1:ni,:),[],'all'));
    minimumTP=min(minimumTP,min(sol.y(ni+1:end,:),[],'all'));
    hit=find(targetTimes>t0+timeTol & targetTimes<=t1+timeTol);
    if ~isempty(hit)
        queryTimes=targetTimes(hit); queryState=deval(sol,queryTimes);
        prediction(hit)=queryState(ni,:)';
        if storeDetail
            for j=1:numel(hit)
                qy=queryState(:,j); SMX=[Cin;qy(1:ni);qy(ni)];
                TP=[0;qy(ni+1:end);qy(end)];
                profiles(end+1)=struct('Time_d',queryTimes(j),'Phase',phase, ...
                    'SMX',SMX,'TP',TP); %#ok<AGROW>
            end
        end
    end
end
result=struct('parameters',p,'target_times',targetTimes, ...
    'prediction_ug_L',prediction,'profiles',profiles,'z_m',settings.z, ...
    'R',R,'min_SMX',minimumSMX,'min_TP',minimumTP);
end
