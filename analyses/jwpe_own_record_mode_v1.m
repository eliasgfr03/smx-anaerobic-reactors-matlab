function jwpe_own_record_mode_v1(b,bundleFile,bundleSHA256,codeHash)
%JWPE_OWN_RECORD_MODE_V1 Append-only source mode, safe across clean resumes.
if ~isfolder(b.folder),return;end
modeFile=fullfile(b.folder,'execution_mode.json');
if isfile(modeFile)
    existing=jsondecode(fileread(modeFile));
    assert(strcmp(existing.mode,b.mode) && strcmp(existing.analysis,b.analysis) && ...
        strcmp(existing.reactor,b.reactor) && strcmp(existing.codeHash,codeHash), ...
        'JWPE:Own:Resume','Execution scope/code changed.');
else
    mode=struct('mode',b.mode,'analysis',b.analysis,'reactor',b.reactor, ...
        'bundleFile',bundleFile,'bundleSHA256',bundleSHA256,'codeHash',codeHash);
    m1_atomic_v1(modeFile,jsonencode(mode),'text',false);
end
closed=fullfile(b.folder,'source_receipt.json');
if isfile(closed)
    identity=struct('modeSHA256',m1_hash_v1(modeFile,'file'), ...
        'closedSourceSHA256',m1_hash_v1(closed,'file'));
    file=fullfile(b.folder,'execution_mode_binding.json');
    if isfile(file)
        assert(isequaln(jsondecode(fileread(file)),identity), ...
            'JWPE:Own:Resume','Closed source or mode binding changed.');
    else
        m1_atomic_v1(file,jsonencode(identity),'text',false);
    end
end
end
