function result=run_ofl_own_v1(b)
%RUN_OFL_OWN_V1 Own-input source OFL searches with named callback persistence.
g1=strcmp(b.analysis,'ofl_g1_screen');
if g1
    kinds={'GLOBAL','LOCAL'};caps=[100 60];rawMax=162;n=4;
else
    kinds={'A','B','LOCAL'};caps=[200 200 125];rawMax=528;n=1;
end
shortBudgetRequested=isfield(b,'shortBudget');
if shortBudgetRequested
    assert(strcmp(b.mode,'test'),'JWPE:Own:OFLShort','Short budgets require an explicit test job.');
    if g1
        assert(isequal(b.shortBudget.outerCalls,[20 10]) && b.shortBudget.rawMax==32, ...
            'JWPE:Own:OFLShort','The short OFL-G1 budget is 20/10 calls and 32 raw forwards.');
        minimumCalls=[10 8];
    else
        assert(isequal(b.shortBudget.outerCalls,[20 20 10]) && b.shortBudget.rawMax==53, ...
            'JWPE:Own:OFLShort','Short OFL calibration uses 20/20/10 calls and 53 raw forwards.');
        minimumCalls=[10 10 8];
    end
    caps=b.shortBudget.outerCalls;rawMax=b.shortBudget.rawMax;
end
folder=jwpe_own_output_v1(b.folder);
state=struct('b',b,'folder',folder,'caps',caps,'rawMax',rawMax,'block',0, ...
    'calls',zeros(size(caps)),'raw',0,'pending',false,'best',[], ...
    'keys',strings(0,1),'values',{{}});
jwpe_ofl_own_state_v1('put',state);
registryCleanup=onCleanup(@()jwpe_ofl_own_state_v1('clear'));
assert(isa(registryCleanup,'onCleanup'));
old=rng;restore=onCleanup(@()rng(old));assert(isa(restore,'onCleanup'));
blocks=cell(size(kinds));
for k=1:numel(kinds)
    s=jwpe_ofl_own_state_v1('get');s.block=k;jwpe_ofl_own_state_v1('put',s);
    kind=kinds{k};
    checkpoint=fullfile(folder,['optimizer_' kind '.mat']);
    if g1
        options=g1s_options_v1(kind,b.reactor,b.config,checkpoint);
        if k==1,rng(b.config.optimizer.seeds.(b.reactor),'twister');end
    else
        if strcmp(b.reactor,'CS'),options=ofl_options_v1(kind,checkpoint);
        else,options=pa_options_v1(kind,b.config,checkpoint);end
        if k<=2,rng(b.config.optimizer.seeds.([b.reactor '_' kind]),'twister');end
    end
    if shortBudgetRequested
        options=optimoptions(options,'MaxFunctionEvaluations',caps(k),'Display','off');
    end
    try
        if strcmp(kind,'LOCAL')
            [z,f,flag,output]=patternsearch(@jwpe_ofl_own_objective_v1,s.best.z, ...
                [],[],[],[],zeros(1,n),ones(1,n),[],options);
        else
            [z,f,flag,output]=surrogateopt(@jwpe_ofl_own_objective_v1,zeros(1,n),ones(1,n),options);
        end
    catch ME
        s=jwpe_ofl_own_state_v1('get');
        if strcmp(ME.identifier,'JWPE:Own:OFLCallCap') && ~isempty(s.best)
            z=s.best.z;f=s.best.fit.nll;flag=0;output=struct('message','Objective cap reached.');
        else
            rethrow(ME)
        end
    end
    s=jwpe_ofl_own_state_v1('get');selected=s.best;
    if shortBudgetRequested
        assert(s.calls(k)>=minimumCalls(k),'JWPE:Own:OFLShort','Optimizer block was not exercised.');
    end
    repeated=jwpe_ofl_own_evaluate_v1(selected.z,true);
    if g1,check=g1s_recheck_v1(selected,repeated,b.config);
    else,check=ofl_recheck_v1(selected,repeated,b.config);end
    m1_atomic_v1(fullfile(folder,['recheck_' kind '.mat']), ...
        struct('selected',selected,'recheck',repeated,'check',check),'mat',false);
    assert(check.pass,'JWPE:Own:OFLRecheck','Independent raw recheck failed.');
    [blocks{k},~]=s16_data_only_v1(struct('kind',kind,'z',z,'f',f, ...
        'exitflag',flag,'output',output,'check',check));
end
s=jwpe_ofl_own_state_v1('get');
result=struct('reactor',b.reactor,'winner',repeated,'context',b.context,'config',b.config, ...
    'blocks',{blocks},'calls',s.calls,'rawForwards',s.raw,'phaseIIICount',0,'horizon_d',94);
m1_atomic_v1(fullfile(folder,'result.mat'),result,'mat',false);
jwpe_closed_source('close',folder,{'result.mat'});
end
