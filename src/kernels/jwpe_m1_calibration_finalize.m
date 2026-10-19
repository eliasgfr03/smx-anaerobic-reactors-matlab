function result = jwpe_m1_calibration_finalize(runDirectory,state)
%JWPE_M1_CALIBRATION_FINALIZE Save compact final artifacts without a forward.
%   Existing completed artifacts are checked by their recorded SHA-256, not
%   overwritten. The mutable run state and optimizer checkpoint are not
%   included in the immutable final-payload manifest.
if ~isfield(state,'result') || isempty(state.result)
    state.result = jwpe_m1_calibration_result(state);
    state.outputRecords = struct('File',{},'Bytes',{},'SHA256',{});
    jwpe_run_write(runDirectory,'run_state.mat',state,'mat',true);
end
result = state.result;
parameter = [result.parameterNames,"sigmaA","sigmaP"].';
units = [result.parameterUnits,"ug/L","1"].';
value = [result.theta,result.sigmaA,result.sigmaP].';
parameters = table(parameter,units,value,'VariableNames', ...
    {'Parameter','Unit','Estimate'});
prediction = table(result.observationTimes_d,result.observed_ug_L, ...
    result.prediction_ug_L,result.phaseI,result.phaseII,'VariableNames', ...
    {'Time_d','Observed_ug_L','Simulated_ug_L','PhaseI','PhaseII'});
summary = struct('status',result.status,'reactor',result.reactor, ...
    'nll',result.nll,'recheckNLL',result.recheckNLL, ...
    'recheckDelta',result.recheckDelta,'optimizerCalls',result.optimizerCalls, ...
    'rawForwards',result.rawForwards,'cacheHits',result.cacheHits, ...
    'invalidEvaluations',result.invalidEvaluations,'failures',0,'retries',0, ...
    'phaseIIIExcluded',true,'horizon_d',94,'identity',result.identity);
names = {'result.mat','parameters.csv','prediction.csv','trace.csv','summary.json'};
values = {result,parameters,prediction,result.trace,jsonencode(summary)};
kinds = {'mat','table','table','table','text'};
for i=1:numel(names)
    state = local_save(runDirectory,state,names{i},values{i},kinds{i});
end
records = struct2table(state.outputRecords);
state = local_save(runDirectory,state,'manifest.csv',records,'table');
state.status = 'COMPLETE';
jwpe_run_write(runDirectory,'run_state.mat',state,'mat',true);
end

function state = local_save(folder,state,leaf,value,kind)
file = fullfile(folder,leaf);
if isfile(file)
    assert(~isempty(state.outputRecords), ...
        'JWPE:Public:Output','Unregistered existing artifact requires review.');
    index = find(strcmp({state.outputRecords.File},leaf),1);
    assert(~isempty(index),'JWPE:Public:Output', ...
        'Existing artifact was not recorded; preserve it and review.');
    info = dir(file);
    assert(info.bytes==state.outputRecords(index).Bytes && ...
        strcmp(m1_hash_v1(file,'file'),state.outputRecords(index).SHA256), ...
        'JWPE:Public:Output','Existing completed artifact identity mismatch.');
else
    jwpe_run_write(folder,leaf,value,kind,false);
    info = dir(file);
    state.outputRecords(end+1,1) = struct('File',leaf,'Bytes',info.bytes, ...
        'SHA256',m1_hash_v1(file,'file'));
    jwpe_run_write(folder,'run_state.mat',state,'mat',true);
end
end
