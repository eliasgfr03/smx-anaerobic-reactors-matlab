function [binding,restore]=jwpe_own_environment_v1(bindingFile)
%JWPE_OWN_ENVIRONMENT_V1 Verify explicit code files, use process-local paths.
binding=jsondecode(fileread(bindingFile));
root=fileparts(bindingFile);
for k=1:numel(binding.files)
    relative=binding.files(k).path;
    assert(~java.io.File(relative).isAbsolute() && ~contains(relative,'..'), ...
        'JWPE:Own:Code','Code paths must stay inside the package.');
    binding.files(k).path=fullfile(root,relative);
end
assert(strcmp(binding.schemaVersion,'JWPE_EXECUTION_CODE_v1') && ...
    isstruct(binding.files) && ~isempty(binding.files), ...
    'JWPE:Own:Code','Explicit code binding required.');
old=path;restore=onCleanup(@()path(old));
names=strings(numel(binding.files),1);folders=strings(numel(binding.files),1);
for k=1:numel(binding.files)
    item=binding.files(k);info=dir(item.path);
    assert(isscalar(info) && info.bytes==item.bytes && ...
        strcmp(jwpe_local_hash_v1(item.path),item.sha256), ...
        'JWPE:Own:Code','Code binding mismatch.');
    [folders(k),names(k)]=fileparts(item.path);
end
assert(numel(unique(names))==numel(names),'JWPE:Own:Code','Ambiguous module names.');
for folder=unique(folders).'
    addpath(char(folder),'-begin');
end
for k=1:numel(binding.files)
    assert(strcmpi(which(char(names(k))),binding.files(k).path), ...
        'JWPE:Own:Code','Effective function is shadowed.');
end
if isfield(binding,'assets')
    for k=1:numel(binding.assets)
        item=binding.assets(k);relative=item.path;
        assert(~java.io.File(relative).isAbsolute() && ~contains(relative,'..'));
        file=fullfile(root,relative);info=dir(file);
        assert(isscalar(info) && info.bytes==item.bytes && ...
            strcmp(jwpe_local_hash_v1(file),item.sha256), ...
            'JWPE:Own:Code','Method recipe identity mismatch.');
    end
end
binding.codeHash=jwpe_local_hash_v1(bindingFile);
end

function value=jwpe_local_hash_v1(file)
f=fopen(file,'rb');assert(f>=0);cleanup=onCleanup(@()fclose(f));
assert(isa(cleanup,'onCleanup'));bytes=fread(f,Inf,'*uint8');
md=java.security.MessageDigest.getInstance('SHA-256');md.update(typecast(bytes,'int8'));
value=lower(reshape(dec2hex(typecast(md.digest(),'uint8'),2).',1,[]));
end
