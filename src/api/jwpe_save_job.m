function job=jwpe_save_job(payload,file)
%JWPE_SAVE_JOB Save an explicit execution specification without running it.
% MAT files must be trusted: they can contain MATLAB objects/function handles.
info=jwpe_package_info();
payload.identity.codeHash=info.codeHash;
jwpe_own_validate_v1(payload);
assert(java.io.File(char(file)).isAbsolute(),'JWPE:Job:Path','Choose an absolute job path.');
assert(~isfile(file) && ~isfolder(file),'JWPE:Job:Overwrite','Job destination already exists.');
parent=fileparts(file);
if ~isfolder(parent),[ok,msg]=mkdir(parent);assert(ok,'JWPE:Job:Path','%s',msg);end
m1_atomic_v1(file,payload,'mat',false);
job=struct('file',char(file),'sha256',m1_hash_v1(file,'file'), ...
    'analysis',payload.analysis,'reactor',payload.reactor,'outputFolder',payload.folder);
end
