function result=run_own_analysis_v1(bundleFile,bundleSHA256,action)
%RUN_OWN_ANALYSIS_V1 Prepare or explicitly execute one hash-bound own-input job.
assert(ismember(string(action),["prepare","execute"]), ...
    'JWPE:Own:Action','Choose prepare or execute explicitly.');
bindingFile=fullfile(fileparts(fileparts(mfilename('fullpath'))),'code_manifest.json');
[binding,restore]=jwpe_own_environment_v1(bindingFile);
assert(isa(restore,'onCleanup'));
assert(strcmp(m1_hash_v1(bundleFile,'file'),bundleSHA256), ...
    'JWPE:Own:Identity','Execution bundle identity mismatch.');
q=load(bundleFile,'payload');assert(isfield(q,'payload'));
b=q.payload;route=jwpe_own_validate_v1(b);
assert(strcmp(b.identity.codeHash,binding.codeHash), ...
    'JWPE:Own:Identity','Execution bundle was prepared for different code.');
target=which(route.target);
assert(~isempty(target) && strcmp(fileparts(target),fileparts(mfilename('fullpath'))), ...
    'JWPE:Own:Path','Own controller shadowed or missing.');
if strcmp(action,'prepare')
    result=struct('status','OWN_EXECUTOR_BOUND_NOT_RUN','route',route, ...
        'controllerFile',target,'controllerSHA256',m1_hash_v1(target,'file'), ...
        'bundleSHA256',bundleSHA256,'outputFolder',b.folder, ...
        'executorLinked',true,'scientificExecutionPerformed',false, ...
        'dynamicScientificQualification',false);return
end
assert(isfield(b,'executeScientific') && isequal(b.executeScientific,true), ...
    'JWPE:Own:ScienceHeld','Bundle must explicitly request scientific execution.');
b=jwpe_own_production_guard_v1(b);
previousScope=jwpe_output_scope(b.folder);
restoreScope=onCleanup(@()jwpe_output_scope(previousScope));
assert(isa(restoreScope,'onCleanup'));
result=feval(route.target,b);
if isstruct(result)
    result.executionMode=b.mode;
    result.testOnly=strcmp(b.mode,'test');
end
jwpe_own_record_mode_v1(b,bundleFile,bundleSHA256,binding.codeHash);
end
