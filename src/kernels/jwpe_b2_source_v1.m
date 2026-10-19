function value=jwpe_b2_source_v1(file,kind,permission)
%JWPE_B2_SOURCE_V1 Read only one explicitly hash-bound completed input.
assert(nnz(strcmp({permission.inputFiles.path},file))==1, ...
    'JWPE:B2:Binding','Requested input was not separately authorized.');
[~,name,ext]=fileparts(file);
assert(~strcmpi([name ext],'latest.mat'),'JWPE:B2:Active','Never load active capsules.');
hash=m1_hash_v1(file,'file');
switch string(kind)
    case "csv"
        value=readtable(file,'VariableNamingRule','preserve');
    case "mat"
        q=load(file,'payload');
        assert(isfield(q,'payload') && isstruct(q.payload) && isscalar(q.payload), ...
            'JWPE:B2:Field','Explicit scalar saved payload required.');
        value=q.payload;
    otherwise
        error('JWPE:B2:Type','Unsupported saved-source kind.');
end
assert(strcmp(hash,m1_hash_v1(file,'file')),'JWPE:B2:Changed','Source changed while reading.');
end
