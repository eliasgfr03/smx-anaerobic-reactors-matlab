function result = PF_simulate_model(theta,data,settings,targetTimes,storeProfiles)
%PF_SIMULATE_MODEL Forward-only PF-AnFBR simulation engine.
%
% v3 STANDARD NUMERICAL ENGINE (2026-08-13)
% The reduced 138-state ode15s implementation now supplies the validated
% sparse Jacobian pattern from PF_jpattern_reduced(settings). This is a
% computational acceleration only: physical equations, spatial operators,
% tolerances, forcing, breakpoints and reporting logic are unchanged.
%
% theta order: [Kd kSigma Fdir kG tinf Ai]
%
% Numerical implementation:
%   * reduced 138-state ODE (69 interior SMX + 69 interior TP states);
%   * ode15s;
%   * TVD/MUSCL MINMOD advection;
%   * centered second-order dispersion;
%   * NEXT-ZOH influent;
%   * phase switches at 49 and 94 d.
%
% Numerical organization:
%   * ode15s is restarted only at physical forcing/hydraulic breakpoints;
%   * requested reporting/profile times do NOT create solver restarts;
%   * reporting values inside an integration segment are evaluated with deval.
%
% The reduced ODE form is an organizational implementation of the same
% boundary conditions used by the accepted final-GSA model.

if nargin < 5
    storeProfiles = false;
end

p = JWPE_parameter_struct(theta);
R = 1 + p.Kd*settings.XTSS_g_L;
ni = settings.node_count-2;
y = zeros(2*ni,1);

targetTimes = unique(targetTimes(:));
endTime = max([targetTimes;data.Time_d]);

% Integration breakpoints are restricted to actual discontinuities in the
% model inputs/settings plus the final integration horizon. In particular,
% arbitrary output/profile times are not inserted here.
integrationBreaks = unique([0;data.Time_d;settings.switch_days(:);endTime]);
integrationBreaks = integrationBreaks( ...
    integrationBreaks>=0 & integrationBreaks<=endTime);

prediction = nan(numel(targetTimes),1);
profiles = struct('Time_d',{},'Phase',{},'SMX',{},'TP',{});
minimumSMX = inf;
minimumTP = inf;
S = PF_jpattern_reduced(settings);
assert(isequal(size(S),[2*ni 2*ni]),'JPattern/state-size mismatch.');
opts = odeset('RelTol',settings.RelTol,'AbsTol',settings.AbsTol, ...
    'JPattern',S);
timeTol = 1e-10;

for k = 1:numel(integrationBreaks)-1
    t0 = integrationBreaks(k);
    t1 = integrationBreaks(k+1);
    phase = 1 + (t0>=settings.switch_days(1)) + ...
                (t0>=settings.switch_days(2));

    Cin = JWPE_next_zoh_influent(t0,data);
    Dax = settings.axial_dispersion_m2_d(phase);
    v = settings.axial_velocity_m_d(phase);

    rhs = @(t,z) PF_mass_balances(t,z,Cin,Dax,v,R,p,settings);

    % Return the solution structure so requested reporting times can be
    % evaluated without forcing additional ode15s restarts.
    sol = ode15s(rhs,[t0 t1],y,opts);
    y = sol.y(:,end);

    minimumSMX = min(minimumSMX,min(sol.y(1:ni,:),[],'all'));
    minimumTP  = min(minimumTP,min(sol.y(ni+1:end,:),[],'all'));

    % Every target strictly after t0 and up to/including t1 belongs to this
    % segment. A target that coincides with a physical breakpoint therefore
    % keeps the left-limit forcing/phase convention used by the previous
    % implementation.
    hit = find(targetTimes > t0 + timeTol & ...
               targetTimes <= t1 + timeTol);

    if ~isempty(hit)
        queryTimes = targetTimes(hit);
        queryState = deval(sol,queryTimes);

        % Effluent = last differential node, consistent with the accepted
        % final Python GSA engine.
        prediction(hit) = queryState(ni,:)';

        if storeProfiles
            for j = 1:numel(hit)
                qy = queryState(:,j);
                SMX = [Cin;qy(1:ni);qy(ni)];
                TP  = [0;qy(ni+1:end);qy(end)];
                profiles(end+1) = struct( ...
                    'Time_d',queryTimes(j), ...
                    'Phase',phase, ...
                    'SMX',SMX, ...
                    'TP',TP); %#ok<AGROW>
            end
        end
    end
end

result = struct();
result.parameters = p;
result.target_times = targetTimes;
result.prediction_ug_L = prediction;
result.profiles = profiles;
result.z_m = settings.z;
result.R = R;
result.min_SMX = minimumSMX;
result.min_TP = minimumTP;
end
