function result=run_pf_dispersion_own_v1(b)
%RUN_PF_DISPERSION Full defaults with an explicit bounded test-only mode.
assert(nargin==1 && isequal(b.executeScientific,true),'JWPE:Public:ScienceHeld','PF scenario computation held.');
cfg=b.config;ctx=b.context;selected=b.selected;baseline=b.baseline;
nDraws=500;nPairs=6000;rawMax=5500;
if isfield(b,'shortBudget')
 assert(strcmp(b.mode,'test') && isstruct(b.shortBudget) && ...
  all(isfield(b.shortBudget,{'selectedRows','rawMax'})) && ...
  b.shortBudget.selectedRows==4 && b.shortBudget.rawMax==8 && ...
  isequal(double(cfg.f(:).'),[0 1 2]) && cfg.baselineIndex==2 && ...
  cfg.selectedRows==4 && cfg.logicalPairs==12 && cfg.rawForwardHardMax==8 && ...
  height(selected)==4 && size(baseline.mu,1)==4, ...
  'JWPE:Own:PFDispersionShort','Short dispersion budgets require an explicit test job.');
 nDraws=4;nPairs=12;rawMax=8;
end
folder=jwpe_own_output_v1(b.folder);
assert(isequal(ctx.fullTimes_d,baseline.times_d));
assert(isequal(selected.ChainID,baseline.selected.ChainID) && isequal(selected.RowID,baseline.selected.RowID));
names={'Kd','kb','kG','tinf','Ai','sigmaA','sigmaP'};
delta=abs(selected{:,names}-baseline.selected{:,names});
assert(all(delta<=64*eps(max(1,abs(baseline.selected{:,names}))),'all'));
[found,loc]=ismember(ctx.forcingData.Time_d,ctx.fullTimes_d);assert(all(found));
policy=jwpe_phase_policy_v1(ctx.forcingData.Time_d);phase=struct('phaseI',policy.phaseI,'phaseII',policy.phaseII,'phaseIII',policy.phaseIII);
means=zeros(nPairs,4);raw=0;
for c=1:numel(cfg.f)
 for d=1:nDraws
  index=(c-1)*nDraws+d;
  if c==cfg.baselineIndex,cout=baseline.mu(d,:).';else
   assert(raw<rawMax);theta=selected{d,{'Kd','kb','kG','tinf','Ai'}};
   cout=pf_dax_forward_v1(ctx,theta,cfg.f(c),cfg);raw=raw+1;
  end
  means(index,:)=pf_dax_math_v1('drawmeans',cout(loc).',ctx.forcingData.Cin_ug_L,phase);
 end
 m1_atomic_v1(fullfile(folder,'latest.mat'),struct('completedCoordinate',c,'means',means(1:c*nDraws,:),'rawForwards',raw),'mat',true);
end
assert(raw==rawMax);[summary,paired]=pf_dax_math_v1('summaries',means,cfg);
result=struct('summary',summary,'paired',paired,'drawMeans',means,'coordinates',pf_dax_coordinates_v1(cfg), ...
 'rawForwards',raw,'baselineReuses',nDraws,'observationErrorDraws',0);
m1_atomic_v1(fullfile(folder,'result.mat'),result,'mat',false);
end
