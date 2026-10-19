function score=run_ofl_holdout_own_v1(b)
%RUN_OFL_TEMPORAL_HOLDOUT One saved day-94-state continuation, fixed error scales.
assert(nargin==1 && isequal(b.executeScientific,true),'JWPE:Public:ScienceHeld','OFL holdout held.');
reactor=b.reactor;assert(ismember(reactor,{'CS','PF'}));
folder=jwpe_own_output_v1(b.folder);cfg=b.config;bundle=b.acceptedCalibration;file=b.responseFile;
opts=detectImportOptions(file);opts.SelectedVariableNames={'Time_d','Cin_ug_L'};
forcing=readtable(file,opts);ctx=bundle.context;ctx.forcing=forcing;ctx.startTime=94;ctx.stopTime=145;
ctx.outputTimes=forcing.Time_d;ctx.auditTimes=unique([(94:.5:145).';forcing.Time_d]);
if strcmp(reactor,'CS'),ctx.initial=p3v_cont_v1('remap',bundle.terminal,2,3);else,ctx.initial=bundle.terminal;end
ctx=rmfield(ctx,intersect(fieldnames(ctx),{'observations','observed_ug_L','observationPhaseI','observationPhaseII'}));
sim=ofl_sim_v1(ctx,bundle.kb,cfg);
m1_atomic_v1(fullfile(folder,'prediction.mat'),rmfield(sim,{'segments'}),'mat',false);
gate=jwpe_prediction_gate('close',folder);jwpe_prediction_gate('require',gate);
response=jwpe_eval_io('readtable',file);score=a1p3_score_v1(response,sim.Cout,bundle.sigmaA,bundle.sigmaP);
m1_atomic_v1(fullfile(folder,'score.mat'),score,'mat',false);
end
