function [payload,contract]=jwpe_job_template(analysis,reactor)
%JWPE_JOB_TEMPLATE Describe a job to complete; no solver or file creation.
% Empty fields are placeholders, not valid scientific defaults. Complete the
% nested structures using the corresponding controller before saving a job.
contract=jwpe_job_contract(analysis,reactor);
payload=struct('schemaVersion','JWPE_OWN_EXECUTION_v1', ...
    'analysis',char(analysis),'reactor',char(reactor),'mode','test', ...
    'runID','','folder','','identity', ...
    struct('datasetID','','methodID',''),'executeScientific',false);
for k=1:numel(contract.requiredFields)
    payload.(contract.requiredFields{k})=[];
end
end
