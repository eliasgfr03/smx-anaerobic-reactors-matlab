function result = jwpe_capacity_read_run(folder,stage,mode)
%JWPE_CAPACITY_READ_RUN Verify all completed payloads before using a run.
if nargin<3,mode='production';end
assert(java.io.File(char(folder)).isAbsolute() && isfolder(folder), ...
    'JWPE:Capacity:Path','Supply an existing absolute result folder.');
full=char(java.io.File(folder).getCanonicalPath());
T=readtable(fullfile(full,'manifest.csv'),'Delimiter',',', ...
    'VariableNamingRule','preserve','TextType','string');
expected=["result.mat";"comparison.csv";"pointwise.csv";"activity.csv";"summary.json"];
assert(height(T)==5 && isequal(T.File,expected), ...
    'JWPE:Capacity:Manifest','Incomplete or reordered manifest.');
for i=1:height(T)
    assert(~contains(T.File(i),["/","\",".."]), ...
        'JWPE:Capacity:Manifest','Payload name must be a safe leaf.');
    file=fullfile(full,char(T.File(i))); info=dir(file);
    assert(isscalar(info) && info.bytes==T.Bytes(i) && ...
        strcmp(m1_hash_v1(file,'file'),T.SHA256(i)), ...
        'JWPE:Capacity:Manifest','Payload identity mismatch.');
end
q=load(fullfile(full,'result.mat'),'payload'); result=q.payload;
jwpe_require_source_mode_v1(folder,result,mode);
acceptedStatus=strcmp(result.status,'TEMPORAL_COMPARISON_COMPLETE');
if strcmp(result.status,'TEST_ONLY_TEMPORAL_COMPLETE')
    acceptedStatus=strcmp(mode,'test') && result.testOnly && ~result.productionCertified && ...
        strcmp(result.role,'SYNTHETIC_TEST_ONLY') && strcmp(result.identity.dataClassification,'SYNTHETIC_TEST_ONLY');
end
assert(strcmp(result.stage,stage) && acceptedStatus ...
    && result.nObs==33 && result.horizon_d==94 && ~result.phaseIIIAccessed, ...
    'JWPE:Capacity:Incomplete','Unexpected stage or incomplete result.');
end
