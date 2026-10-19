function route=jwpe_own_route_v1(analysis,reactor)
%JWPE_OWN_ROUTE_V1 Explicit own-input controller registry, not legacy loaders.
if strcmp(analysis,'pf_dispersion')
    assert(strcmp(reactor,'PF'),'JWPE:Own:Reactor','PF dispersion requires PF.');
elseif strcmp(analysis,'cs_time_equivalence')
    assert(strcmp(reactor,'CS'),'JWPE:Own:Reactor','CS equivalence requires CS.');
end
switch analysis
    case 'observation_error_joint'
        target='finalize_oem_joint_own_v1';fields={'csRun','pfRun'};
    case 'capacity_joint'
        target='finalize_capacity_joint_own_v1';fields={'csBase','csLog2','pfBase','pfLog2'};
    case 'calibration_m1_fixed'
        target='run_m1_own_v1';fields={'inputs','action'};
    case 'observation_error_selection'
        target='run_oem_own_v1';fields={'inputs'};
    case 'capacity_g1_a1'
        target='run_capacity_own_v1';fields={'context','core','capacityBase','capacityConfig','thetaRef'};
    case 'capacity_log2'
        target='run_log2_own_v1';fields={'context','core','capacityBase','capacityConfig','thetaRef','g1','g1Reference'};
    case 'pl_m0'
        target='run_m0_cs_own_v1';if strcmp(reactor,'PF'),target='run_m0_pf_own_v1';end
        fields={'forcing','observations','settings','core','catalogue','caseConfig'};
    case {'pl_m1_free','pl_m1_fixed','pl_m1_free_closure','pl_m1_fixed_closure'}
        target='run_m1_pl_own_v1';fields={'context','caseConfig','catalogSHA256'};
        if strcmp(analysis,'pl_m1_fixed_closure')
            fields=[fields,{'anchor','candidate','campaignID'}];
        end
    case 'gsa'
        target='run_gsa_own_v1';fields={'context','inputs'};
    case 'mcmc'
        target='run_mcmc_own_v1';fields={'context','config','initial','action','sweepLimit'};
    case 'selection'
        target='run_selection_own_v1';fields={'config','chains','chainCertification'};
    case 'propagation'
        target='run_propagation_own_v1';fields={'context','config','selected'};
    case 'temporal_holdout'
        target='run_holdout_own_v1';fields={'context','config','selected','reference','responseFile'};
    case 'external_smx'
        target='run_external_own_v1';fields={'context','config','selected','study','responseFile'};
    case {'ofl_calibration','ofl_g1_screen'}
        target='run_ofl_own_v1';fields={'context','config'};
    case 'ofl_holdout'
        target='run_ofl_holdout_own_v1';fields={'config','acceptedCalibration','responseFile'};
    case 'cs_time_equivalence'
        target='run_cs_time_own_v1';fields={'chainsCS','chainsPF','config'};
    case 'pf_dispersion'
        target='run_pf_dispersion_own_v1';fields={'context','config','selected','baseline'};
    case 'numeric_products'
        target='run_numeric_own_v1';fields={'product','numericInput','numericPolicy'};
    case 'pl_finalize'
        target='finalize_pl_own_v1';fields={'model','nativeRuns','catalogSHA256','requiredOrigins', ...
            'anchorCaseId','points','D95'};
    otherwise
        error('JWPE:Own:Analysis','Unknown analysis.');
end
route=struct('analysis',analysis,'reactor',reactor,'target',target, ...
    'requiredFields',{fields},'scientificExecutionOnInvoke',true, ...
    'legacyControllerCalled',false,'dynamicScientificQualification',false);
end
