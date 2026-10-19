function out = jwpe_closed_manifest_v1(action,folder)
% Logs must be closed; never target a running MATLAB output directory.
switch action
    case 'manifest'
        target=fullfile(folder,'manifest.json'); assert(~isfile(target));
        files=dir(fullfile(folder,'*')); rows=struct('path',{},'bytes',{},'sha256',{});
        for i=1:numel(files)
            if files(i).isdir || strcmp(files(i).name,'manifest.json'), continue; end
            rows(end+1)=struct('path',files(i).name,'bytes',files(i).bytes, ...
                'sha256',m1_hash_v1(fullfile(folder,files(i).name),'file')); %#ok<AGROW>
        end
        out=struct('schema','JWPE_05B_RUN_MANIFEST_v1','payloads',rows);
        m1_atomic_v1(target,jsonencode(out),'text',false);
    case 'read'
        manifest=jsondecode(fileread(fullfile(folder,'manifest.json')));
        required={'configuration.mat','result.mat','ledger.mat','identity.mat'};
        assert(all(ismember(required,{manifest.payloads.path})));
        for b=reshape(manifest.payloads,1,[])
            assert(~any(contains(b.path,{'/','\','..'})));
            f=fullfile(folder,b.path); info=dir(f);
            assert(numel(info)==1 && info.bytes==b.bytes && ...
                strcmp(m1_hash_v1(f,'file'),b.sha256));
        end
        r=load(fullfile(folder,'result.mat'),'payload'); out=r.payload;
    otherwise
        error('JWPE:Persist:Action','Unsupported persistence action.');
end
end
