function settings = jwpe_interface_settings_v1(physical,method,profile)
%JWPE_INTERFACE_SETTINGS_V1 Build source-compatible settings from explicit data.
% No default-settings constructor is called, avoiding embedded measurements.
need={'hydraulicModel','XTSS_g_L','XVSS_g_L','switchDays'};
assert(all(isfield(physical,need)) && all(isfield(method,{'RelTol','AbsTol'})), ...
    'JWPE:Interface:Physics','Required physical/numerical settings missing.');
assert(isscalar(physical.XTSS_g_L) && isscalar(physical.XVSS_g_L) && ...
    isfinite(physical.XTSS_g_L) && physical.XTSS_g_L>0 && ...
    isfinite(physical.XVSS_g_L) && physical.XVSS_g_L>0, ...
    'JWPE:Interface:Biomass','Explicit positive TSS and VSS required.');
assert(isscalar(method.RelTol) && isfinite(method.RelTol) && method.RelTol>0 && ...
    isscalar(method.AbsTol) && isfinite(method.AbsTol) && method.AbsTol>0, ...
    'JWPE:Interface:Solver','Positive explicit scalar tolerances required.');
switches=double(physical.switchDays(:).');
assert(all(isfinite(switches)) && all(diff(switches)>0), ...
    'JWPE:Interface:Physics','Invalid switch times.');
settings=struct('XTSS_g_L',physical.XTSS_g_L,'XVSS_g_L',physical.XVSS_g_L, ...
    'switch_days',switches,'RelTol',method.RelTol,'AbsTol',method.AbsTol);
n=numel(switches)+1;
switch char(string(physical.hydraulicModel))
    case 'CS_TIS'
        assert(all(isfield(physical,{'phaseResidenceTime_h','tanksPerPhase'})), ...
            'JWPE:Interface:Physics','Missing CS phase settings.');
        tm=double(physical.phaseResidenceTime_h(:).');
        tanks=double(physical.tanksPerPhase(:).');
        assert(numel(tm)==n && numel(tanks)==n && all(isfinite(tm)) && all(tm>0) && ...
            all(isfinite(tanks)) && all(tanks>=1 & tanks==fix(tanks)), ...
            'JWPE:Interface:Physics','Invalid CS phase settings.');
        settings.mean_residence_time_h=tm;settings.tanks_in_series=tanks;
    case 'PF_ADM'
        assert(all(isfield(physical,{'length_m','reportingVolume_L','velocity_m_d','Dax_m2_d'})) && ...
            isfield(method,'nodeCount'),'JWPE:Interface:Physics','Missing PF inputs.');
        L=physical.length_m;V=physical.reportingVolume_L;N=method.nodeCount;
        u=double(physical.velocity_m_d(:).');D=double(physical.Dax_m2_d(:).');
        assert(isscalar(L) && isfinite(L) && L>0 && isscalar(V) && isfinite(V) && V>0 && ...
            isscalar(N) && isfinite(N) && N>=3 && N==fix(N) && numel(u)==n && ...
            numel(D)==n && all(isfinite(u)) && all(u>0) && all(isfinite(D)) && all(D>=0), ...
            'JWPE:Interface:Physics','Invalid PF dimensions or coefficients.');
        settings.length_m=L;settings.node_count=N;settings.reporting_volume_L=V;
        settings.axial_velocity_m_d=u;settings.axial_dispersion_m2_d=D;
        settings.z=linspace(0,L,N).';settings.dz=settings.z(2)-settings.z(1);
    otherwise
        error('JWPE:Interface:Physics','Unsupported hydraulic model.');
end
if strcmp(profile,'SMX_ORIGINAL')
    assert(isequal(switches,[49 94]),'JWPE:Interface:Profile','Original switches differ.');
    if isfield(settings,'node_count')
        assert(settings.node_count==71,'JWPE:Interface:Profile','Original PF grid must remain71.');
    end
end
end
