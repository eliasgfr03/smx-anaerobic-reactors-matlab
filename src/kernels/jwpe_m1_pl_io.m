function out = jwpe_m1_pl_io(action,varargin)
switch action
    case 'new'
        env=varargin{1}; cfg=varargin{2}; id=char(varargin{3});
        assert(~isempty(regexp(id,'^[A-Za-z][A-Za-z0-9_-]{0,63}$','once')), ...
            'JWPE:P05B:RunID','Invalid new run identifier.');
        parent=fullfile(env.resultsRoot,cfg.reactor,cfg.id);
        out=fullfile(parent,id);
        assert(~isfolder(out) && ~isfile(out),'JWPE:P05B:Overwrite','Run already exists.');
        [ok,msg]=mkdir(out); assert(ok,'JWPE:P05B:Path','%s',msg);
        m1_atomic_v1(fullfile(out,'configuration.mat'),cfg,'mat',false);
        local_storage_guard(out);
    case 'save'
        out=varargin{1}; name=varargin{2}; value=varargin{3};
        assert(~any(contains(name,{'/','\','..'})),'JWPE:P05B:Path','Invalid output name.');
        m1_atomic_v1(fullfile(out,[name '.mat']),value,'mat',false);
        local_storage_guard(out);
    case 'ledger'
        out=varargin{1}; value=varargin{2};
        m1_atomic_v1(fullfile(out,'ledger.mat'),value,'mat',true);
        local_storage_guard(out);
    case 'manifest'
        out=varargin{1}; jwpe_closed_manifest_v1('manifest',out);
        local_storage_guard(out);
    case 'read'
        out=jwpe_closed_manifest_v1('read',varargin{1});
    otherwise
        error('JWPE:P05B:IO','Unsupported persistence action.');
end
end

function local_storage_guard(out)
files=dir(fullfile(out,'*')); files=files(~[files.isdir]);
assert(sum([files.bytes])<=10*1024*1024,'JWPE:P05B:Storage', ...
    'Run exceeded 10 MiB. Preserve outputs and stop; do not delete or retry.');
end
