function resumed=jwpe_resume_job(job,newJobFile)
%JWPE_RESUME_JOB Prepare a new specification for a compatible saved run.
% Only M1 calibration and MCMC support resume. No solver is called here.
assert(strcmp(m1_hash_v1(job.file,'file'),job.sha256),'JWPE:Job:Identity','Original job changed.');
q=load(job.file,'payload');payload=q.payload;
assert(ismember(payload.analysis,{'calibration_m1_fixed','mcmc'}));
payload.action='resume';
resumed=jwpe_save_job(payload,newJobFile);
end
