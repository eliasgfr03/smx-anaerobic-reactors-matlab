function jwpe_require_source_mode_v1(folder,result,mode)
%JWPE_REQUIRE_SOURCE_MODE_V1 Prevent test sources from entering production.
assert(ismember(string(mode),["test","production"]),'JWPE:Own:SourceMode','Invalid mode.');
if strcmp(mode,'test'),return;end
file=fullfile(folder,'execution_mode.json');
assert(isfile(file),'JWPE:Own:SourceMode','Production requires an explicit source execution-mode record.');
source=jsondecode(fileread(file));
assert(isfield(source,'mode') && strcmp(source.mode,'production'), ...
    'JWPE:Own:SourceMode','Test or unclassified source cannot enter production.');
synthetic=isfield(result,'testOnly') && isequal(result.testOnly,true);
if isfield(result,'cfg') && isfield(result.cfg,'testOnly')
    synthetic=synthetic || isequal(result.cfg.testOnly,true);
end
if isfield(result,'identity') && isfield(result.identity,'dataClassification')
    synthetic=synthetic || strcmp(result.identity.dataClassification,'SYNTHETIC_TEST_ONLY');
end
if isfield(result,'role')
    synthetic=synthetic || contains(string(result.role),'SYNTHETIC');
end
assert(~synthetic,'JWPE:Own:SourceMode','Synthetic source cannot enter production.');
end
