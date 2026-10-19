function result = CS_simulate_model(theta,data,settings,targetTimes,storeDense)
%CS_SIMULATE_MODEL Forward-only CS-AnFBR simulation engine.
%
% theta order: [Kd kSigma Fdir kG tinf Ai]
%
% The continuous calendar-time integration preserves states across sampling
% intervals. At day 94, the conceptual TIS representation changes from two
% to three tanks and the state is conservatively remapped in normalized TIS
% coordinate so the mean aqueous concentration is preserved.

if nargin < 5
    storeDense = false;
end

p = JWPE_parameter_struct(theta);
R = 1 + p.Kd*settings.XTSS_g_L;
targetTimes = unique(targetTimes(:));
endTime = max([targetTimes;data.Time_d]);
events = unique([0;data.Time_d;targetTimes;settings.switch_days(:)]);
events = events(events>=0 & events<=endTime);

N = settings.tanks_in_series(1);
y = zeros(2*N,1);
prediction = nan(numel(targetTimes),1);
minimumSMX = inf;
minimumTP = inf;

% Fixed three-tank storage prevents structure changes when N switches 2->3.
denseT=[]; densePhase=[]; denseCin=[]; denseA=[];
denseSMX=nan(0,3); denseTP=nan(0,3);

opts = odeset('RelTol',settings.RelTol,'AbsTol',settings.AbsTol);

for k = 1:numel(events)-1
    t0 = events(k);
    t1 = events(k+1);
    phase = 1 + (t0>=settings.switch_days(1)) + (t0>=settings.switch_days(2));
    targetN = settings.tanks_in_series(phase);

    if targetN ~= N
        y = CS_conservative_remap(y,N,targetN);
        N = targetN;
    end

    Cin = JWPE_next_zoh_influent(t0,data);
    tm_d = settings.mean_residence_time_h(phase)/24;
    rhs = @(t,z) CS_mass_balances(t,z,Cin,N,tm_d,R,p,settings);

    if storeDense
        tspan = unique([t0:0.25:t1,t1]);
    else
        tspan = [t0 t1];
    end

    [tout,Y] = ode15s(rhs,tspan,y,opts);
    y = Y(end,:)';
    minimumSMX = min(minimumSMX,min(Y(:,1:2:end),[],'all'));
    minimumTP  = min(minimumTP,min(Y(:,2:2:end),[],'all'));

    if storeDense
        nt = numel(tout);
        addSMX = nan(nt,3); addTP = nan(nt,3);
        addSMX(:,1:N) = Y(:,1:2:end);
        addTP(:,1:N)  = Y(:,2:2:end);
        denseT=[denseT;tout(:)]; %#ok<AGROW>
        densePhase=[densePhase;repmat(phase,nt,1)]; %#ok<AGROW>
        denseCin=[denseCin;repmat(Cin,nt,1)]; %#ok<AGROW>
        denseA=[denseA;arrayfun(@(tt)JWPE_activity_G1(tt,p),tout(:))]; %#ok<AGROW>
        denseSMX=[denseSMX;addSMX]; %#ok<AGROW>
        denseTP=[denseTP;addTP]; %#ok<AGROW>
    end

    hit = find(abs(targetTimes-t1)<1e-10);
    if ~isempty(hit)
        prediction(hit) = y(end-1);
    end
end

if storeDense
    dense = table(denseT,densePhase,denseCin,denseA, ...
        denseSMX(:,1),denseSMX(:,2),denseSMX(:,3), ...
        denseTP(:,1),denseTP(:,2),denseTP(:,3), ...
        'VariableNames',{'Time_d','Phase','Cin_ug_L','Activity', ...
        'SMX_tank_1','SMX_tank_2','SMX_tank_3','TP_tank_1','TP_tank_2','TP_tank_3'});
else
    dense = table();
end

result = struct();
result.parameters = p;
result.target_times = targetTimes;
result.prediction_ug_L = prediction;
result.R = R;
result.min_SMX = minimumSMX;
result.min_TP = minimumTP;
result.dense = dense;
end
