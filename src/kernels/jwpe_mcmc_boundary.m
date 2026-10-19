function payload=jwpe_mcmc_boundary(action,folder,payload)
%JWPE_MCMC_BOUNDARY Only complete states can resume; uncertain work remains HOLD.
if nargin<3,payload=[];end
pending=fullfile(folder,'pending.mat');state=fullfile(folder,'latest.mat');
if strcmp(action,'begin')
 assert(~isfile(pending),'JWPE:Public:ResumeHeld','Uncertain operation cannot be replayed.');
 m1_atomic_v1(pending,struct('status','OPERATION_PENDING_NO_RETRY'),'mat',false);
elseif strcmp(action,'commit')
 assert(isfile(pending),'JWPE:Public:ResumeHeld','No active operation.');
 m1_atomic_v1(state,payload,'mat',true);
 receipt=struct('sha256',m1_hash_v1(state,'file'),'sweep',payload.sweep);
 m1_atomic_v1(fullfile(folder,'boundary.json'),jsonencode(receipt),'text',true);
 delete(pending);
elseif strcmp(action,'load')
 assert(~isfile(pending),'JWPE:Public:ResumeHeld','Pending work is held, not silently repeated.');
 b=jsondecode(fileread(fullfile(folder,'boundary.json')));
 assert(strcmp(m1_hash_v1(state,'file'),b.sha256),'JWPE:Public:ResumeHeld','Incomplete boundary.');
 q=load(state,'payload');payload=q.payload;assert(payload.sweep==b.sweep);
else
 error('JWPE:Public:ResumeHeld','Unknown boundary action.');
end
end
