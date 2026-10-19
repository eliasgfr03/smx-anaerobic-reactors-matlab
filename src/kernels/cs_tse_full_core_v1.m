function result = cs_tse_full_core_v1(csChains,pfChains,cfg)
%CS_TSE_FULL_CORE_V1 Apply the accepted equations to every retained draw.

cs = vertcat(csChains{:});
pf = vertcat(pfChains{:});
nCS=size(cs,1); nPF=size(pf,1);
assert(nCS==cfg.chains*cfg.csRowsPerChain && ...
    nPF==cfg.chains*cfg.pfRowsPerChain,'JWPE:CSTSEFULL:Rows');

tauCS_d=cfg.csTau_h/24; tauPF_d=cfg.pfTau_h/24;
phaseFactor=tauCS_d./tauPF_d;
intI=zeros(nCS,1); intII=zeros(nCS,1);
for m=1:nCS
    p=struct('kG',cs(m,3),'tinf',cs(m,4),'Ai',cs(m,5));
    f=@(t)JWPE_activity_G1(t,p);
    intI(m)=integral(f,0,cfg.switchDay,'RelTol', ...
        cfg.integrationRelTol,'AbsTol',cfg.integrationAbsTol);
    intII(m)=integral(f,cfg.switchDay,cfg.inferenceEndDay,'RelTol', ...
        cfg.integrationRelTol,'AbsTol',cfg.integrationAbsTol);
end
weightedCS=tauCS_d(1).*intI+tauCS_d(2).*intII;
weightedPF=tauPF_d(1).*intI+tauPF_d(2).*intII;
integratedFactor=weightedCS./weightedPF;
kbEq=cs(:,2).*phaseFactor;
kbEqIntegrated=cs(:,2).*integratedFactor;

csValues=[cs(:,2) kbEq(:,1) kbEq(:,2) kbEq(:,3) kbEqIntegrated];
csNames=["CS_ORIGINAL" "CS_EQ_PHASE_I" "CS_EQ_PHASE_II" ...
    "CS_EQ_PHASE_III" "CS_EQ_PHASE_I_II"];
pfValues=pf(:,2); pfNames="PF_ORIGINAL";
summary=[ppu_math_v1('summary',csValues,csNames); ...
    ppu_math_v1('summary',pfValues,pfNames)];
summary=addvars(summary,[repmat(nCS,5,1);nPF], ...
    repmat("L/(gVSS d)",6,1),'After','Parameter', ...
    'NewVariableNames',{'N','Unit'});

phase=["I";"II";"III"];
scales=table(phase,cfg.csTau_h(:),cfg.pfTau_h(:),phaseFactor(:), ...
    'VariableNames',{'Phase','TauCS_h','TauPF_L_over_u_h', ...
    'TauRatio_CS_over_PF'});

meanCS=mean(cs(:,2)); meanEq=mean(kbEqIntegrated); meanPF=mean(pf(:,2));
medianCS=local_quantile(cs(:,2),0.5); medianEq=local_quantile(kbEqIntegrated,0.5);
medianPF=local_quantile(pf(:,2),0.5);
meanRatioBefore=meanCS/meanPF; meanRatioAfter=meanEq/meanPF;
medianRatioBefore=medianCS/medianPF; medianRatioAfter=medianEq/medianPF;
meanGapReduction=(meanCS-meanEq)/(meanCS-meanPF);
medianGapReduction=(medianCS-medianEq)/(medianCS-medianPF);
meanRatioReduction=1-meanRatioAfter/meanRatioBefore;
medianRatioReduction=1-medianRatioAfter/medianRatioBefore;
probability=local_probability_greater(kbEqIntegrated,pf(:,2));
comparison=table(meanCS,meanEq,meanPF,meanRatioBefore,meanRatioAfter, ...
    100*meanRatioReduction,100*meanGapReduction,medianCS,medianEq,medianPF, ...
    medianRatioBefore,medianRatioAfter,100*medianRatioReduction, ...
    100*medianGapReduction,mean(integratedFactor), ...
    local_quantile(integratedFactor,0.5),probability, ...
    'VariableNames',{'MeanKbCS','MeanKbEq_I_II','MeanKbPF', ...
    'MeanRatioBefore','MeanRatioAfter','MeanRatioReductionPercent', ...
    'MeanGapReductionPercent','MedianKbCS','MedianKbEq_I_II','MedianKbPF', ...
    'MedianRatioBefore','MedianRatioAfter','MedianRatioReductionPercent', ...
    'MedianGapReductionPercent','MeanTimeFactor_I_II', ...
    'MedianTimeFactor_I_II','ProbabilityKbEqGreaterThanKbPF'});

chainID=[repelem((1:cfg.chains).',cfg.csRowsPerChain); ...
    repelem((1:cfg.chains).',cfg.pfRowsPerChain)];
reactor=[repmat("CS",nCS,1);repmat("PF",nPF,1)];
quantity=[repmat("ORIGINAL_KB",nCS,1);repmat("ORIGINAL_KB",nPF,1)];
value=[cs(:,2);pf(:,2)];
chainBase=table(reactor,chainID,quantity,value,'VariableNames', ...
    {'Reactor','ChainID','Quantity','Value'});
reactor=[repmat("CS",nCS,1);repmat("CS",nCS,1)];
chainID=[repelem((1:cfg.chains).',cfg.csRowsPerChain); ...
    repelem((1:cfg.chains).',cfg.csRowsPerChain)];
quantity=[repmat("EQ_PHASE_I_II",nCS,1);repmat("TIME_FACTOR_I_II",nCS,1)];
value=[kbEqIntegrated;integratedFactor];
chainBase=[chainBase;table(reactor,chainID,quantity,value,'VariableNames', ...
    {'Reactor','ChainID','Quantity','Value'})];
[groups,reactorGroup,chainGroup,quantityGroup]=findgroups( ...
    chainBase.Reactor,chainBase.ChainID,chainBase.Quantity);
[meanBy,sdBy,medianBy,q025By,q975By,nBy]=splitapply(@local_group,chainBase.Value,groups);
chainSummary=table(reactorGroup,chainGroup,quantityGroup,nBy,meanBy,sdBy, ...
    medianBy,q025By,q975By, ...
    'VariableNames',{'Reactor','ChainID','Quantity','N','Mean','SD','Median','Q025','Q975'});

phaseResidual=max(abs(kbEq.*tauPF_d-cs(:,2).*tauCS_d),[],'all');
integratedResidual=max(abs(kbEqIntegrated.*weightedPF-cs(:,2).*weightedCS),[],'all');
checks=["FINITE_OUTPUTS";"EXPECTED_ROWS";"ACTIVITY_INTEGRALS_POSITIVE"; ...
    "PHASEWISE_EXPOSURE_IDENTITY";"INTEGRATED_EXPOSURE_IDENTITY"; ...
    "NO_PAIRWISE_MATRIX_RETAINED"];
pass=[all(isfinite(csValues),'all') && all(isfinite(pfValues),'all'); ...
    nCS==cfg.chains*cfg.csRowsPerChain && ...
        nPF==cfg.chains*cfg.pfRowsPerChain;all(intI>0 & intII>0); ...
    phaseResidual<=cfg.identityTolerance; ...
    integratedResidual<=cfg.identityTolerance;true];
metric=[max(abs(csValues),[],'all');nCS+nPF;min([intI;intII]); ...
    phaseResidual;integratedResidual;0];
qa=table(checks,pass,metric,'VariableNames',{'Check','Pass','Metric'});
assert(all(pass),'JWPE:CSTSEFULL:QA','A full-posterior QA gate failed.');

result=struct('summary',summary,'comparison',comparison,'scales',scales, ...
    'chainSummary',chainSummary,'qa',qa,'phaseResidual',phaseResidual, ...
    'integratedResidual',integratedResidual,'rowsCS',nCS,'rowsPF',nPF, ...
    'combinations',double(nCS)*double(nPF));
end

function q=local_quantile(x,p)
q=ppu_math_v1('quantile',x,p); q=q(1);
end

function probability=local_probability_greater(x,y)
xs=sort(x(:)); ys=sort(y(:)); ny=numel(ys); cursor=1; count=0;
for i=1:numel(xs)
    while cursor<=ny && ys(cursor)<xs(i), cursor=cursor+1; end
    count=count+(cursor-1);
end
probability=count/(double(numel(xs))*double(ny));
end

function varargout=local_group(x)
q=ppu_math_v1('quantile',x,[0.025 0.5 0.975]);
varargout={mean(x),std(x,0),q(2),q(1),q(3),numel(x)};
end
