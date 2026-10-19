function m1_atomic_v1(file,value,kind,replace)
%M1_ATOMIC_V1 Write a new artifact through a same-directory temporary file.

if nargin<4
    replace = false;
end
file = char(file);
parent = fileparts(file);
assert(isfolder(parent),'JWPE:M1:Path', ...
    'Destination directory does not exist: %s',parent);
if isfile(file) && ~replace
    error('JWPE:M1:Overwrite','Refusing to overwrite existing file: %s',file);
end
kind = lower(string(kind));
switch kind
    case "mat"
        tmp = [tempname(parent) '.tmp.mat'];
        payload = value;
        save(tmp,'payload','-v7');
    case "table"
        assert(istable(value),'JWPE:M1:Output','Expected a table.');
        tmp = [tempname(parent) '.tmp.csv'];
        writetable(value,tmp);
    case "text"
        tmp = [tempname(parent) '.tmp.txt'];
        fid = fopen(tmp,'wt');
        assert(fid>=0,'JWPE:M1:Output','Cannot create temporary text file.');
        cleaner = onCleanup(@()fclose(fid));
        fprintf(fid,'%s',char(value));
        clear cleaner
    otherwise
        error('JWPE:M1:Config','Unsupported atomic output kind: %s.',kind);
end
cleanup = onCleanup(@()local_remove(tmp));
[ok,msg] = movefile(tmp,file,'f');
assert(ok,'JWPE:M1:Output','Atomic move failed: %s',msg);
end

function local_remove(file)
if isfile(file)
    delete(file);
end
end

