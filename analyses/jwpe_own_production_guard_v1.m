function b=jwpe_own_production_guard_v1(b)
%JWPE_OWN_PRODUCTION_GUARD_V1 Frozen/certified sources before downstream work.
if strcmp(b.mode,'test'),return;end
if strcmp(b.analysis,'selection')
    [chains,summary]=chain_source(b.chainSourceFolder,b.reactor);
    assert(isequaln(chains,b.chains),'JWPE:Own:Certification','Input chain rows changed.');
    b.chainCertification=struct('warmupExcluded',true,'certified',true, ...
        'diagnostics',summary.diagnostics.table);
elseif strcmp(b.analysis,'cs_time_equivalence')
    cs=chain_source(b.chainSourceCS,'CS');pf=chain_source(b.chainSourcePF,'PF');
    assert(isequaln(cs,b.chainsCS) && isequaln(pf,b.chainsPF), ...
        'JWPE:Own:Certification','Full retained chains differ from closed sources.');
elseif ismember(string(b.analysis),["propagation","temporal_holdout","external_smx","pf_dispersion"])
    reactor=b.reactor;
    if ismember(string(b.analysis),["external_smx","pf_dispersion"]),reactor='PF';end
    require_mode(b.selectionSourceFolder,'selection');
    jwpe_closed_source('require',b.selectionSourceFolder);
    q=load(fullfile(b.selectionSourceFolder,'selected.mat'),'payload');s=q.payload;
    assert(isfield(s,'certified') && s.certified && strcmp(s.mode,'production') && ...
        strcmp(s.reactor,reactor) && isequaln(s.selected,b.selected) && height(s.selected)==500, ...
        'JWPE:Own:Certification','Frozen certified joint selection required.');
elseif strcmp(b.analysis,'ofl_holdout')
    require_mode(b.acceptedFitFolder,'ofl_calibration');
    jwpe_closed_source('require',b.acceptedFitFolder);
    q=load(fullfile(b.acceptedFitFolder,'result.mat'),'payload');p=q.payload;
    assert(strcmp(p.reactor,b.reactor) && p.phaseIIICount==0 && p.horizon_d==94 && ...
        p.config.fixed_Kd_L_gTSS==.170 && p.config.activity_multiplier==1 && ...
        numel(p.blocks)==3 && all(cellfun(@(v)v.check.pass,p.blocks)) && p.winner.valid, ...
        'JWPE:Own:Certification','Incomplete accepted A1 calibration/rechecks.');
    own=struct('reactor',p.reactor,'context',p.context,'kb',p.winner.kb, ...
        'terminal',p.winner.sim.terminal,'sigmaA',p.winner.fit.sigmaA, ...
        'sigmaP',p.winner.fit.sigmaP,'nll',p.winner.fit.nll);
    assert(isequaln(own,b.acceptedCalibration),'JWPE:Own:Certification','Frozen OFL fit changed.');
end
end

function [chains,s]=chain_source(folder,reactor)
require_mode(folder,'mcmc');jwpe_closed_source('require',folder);
q=load(fullfile(folder,'summary.mat'),'payload');s=q.payload;
assert(strcmp(s.reactor,reactor) && s.chains==4 && isfield(s,'certified') && s.certified, ...
    'JWPE:Own:Certification','Certified independent MCMC source required.');
d=s.diagnostics.table;
assert(height(d)==7 && isequal(string(d.Parameter(:)), ...
    ["Kd";"kb";"kG";"tinf";"Ai";"sigmaA";"sigmaP"]) && ...
    all(isfinite(d{:,{'Rhat','BulkESS','TailESS'}}),'all') && ...
    all(d.Rhat<1.01 & d.BulkESS>400 & d.TailESS>400), ...
    'JWPE:Own:Certification','Original convergence criteria not met.');
chains=cell(1,4);
for k=1:4
    q=load(fullfile(folder,sprintf('chain_%02d.mat',k)),'payload');p=q.payload;
    assert(strcmp(p.reactor,reactor) && p.chain==k && p.warmupExcluded && p.rows==s.rowsPerChain && ...
        isequal(size(p.physical),[s.rowsPerChain 7]) && all(isfinite(p.physical),'all'), ...
        'JWPE:Own:Certification','Invalid retained physical chain metadata.');
    chains{k}=p.physical;
end
end

function require_mode(folder,analysis)
assert(~isempty(folder),'JWPE:Own:Certification','Explicit closed source required.');
file=fullfile(folder,'execution_mode.json');binding=fullfile(folder,'execution_mode_binding.json');
assert(isfile(file) && isfile(binding),'JWPE:Own:Certification','Missing source mode binding.');
m=jsondecode(fileread(file));v=jsondecode(fileread(binding));
assert(strcmp(m.mode,'production') && strcmp(m.analysis,analysis) && ...
    strcmp(m1_hash_v1(file,'file'),v.modeSHA256) && ...
    strcmp(m1_hash_v1(fullfile(folder,'source_receipt.json'),'file'),v.closedSourceSHA256), ...
    'JWPE:Own:Certification','Wrong source mode, analysis or payload binding.');
end
