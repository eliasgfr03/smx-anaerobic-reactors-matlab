function result=jwpe_job(job,action)
%JWPE_JOB Validate or execute one explicit job: 'prepare' or 'execute'.
% 'prepare' reads and validates only. 'execute' runs the specified analysis.
assert(isstruct(job) && isscalar(job) && all(isfield(job,{'file','sha256'})), ...
    'JWPE:Job:Schema','Use a job returned by jwpe_save_job or jwpe_prepare_m1.');
result=run_own_analysis_v1(job.file,job.sha256,action);
end
