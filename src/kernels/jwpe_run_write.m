function jwpe_run_write(runDirectory,leaf,value,kind,replace)
%JWPE_RUN_WRITE Write one artifact inside a caller-owned run directory.
%   LEAF is a filename, never a path. The controller creates the run below
%   results/; this helper prevents escape into references or parent folders.
%   Only a run's consolidated state file is replaced during scientific use.
if nargin<5
    replace = false;
end
leaf = char(string(leaf));
assert(~isempty(regexp(leaf,'^[A-Za-z0-9][A-Za-z0-9_.-]{0,63}$','once')) ...
    && ~contains(leaf,'..'),'JWPE:Public:Path','Expected a plain filename.');
target = fullfile(char(runDirectory),leaf);
assert(isfolder(runDirectory) && numel(target)<=245, ...
    'JWPE:Public:Path','Missing run folder or destination path too long.');
m1_atomic_v1(target,value,kind,replace);
end
