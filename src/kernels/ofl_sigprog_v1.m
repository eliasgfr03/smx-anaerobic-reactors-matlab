function ofl_sigprog_v1(file,progress)
%OFL_SIGPROG_V1 Append-only sigma progress; historical source remains intact.
[folder,name] = fileparts(file);
k = ofl_io_v1('nextversion',folder,name,'mat');
ofl_io_v1('write',fullfile(folder,sprintf('%s_v%d.mat',name,k)),progress,'mat');
end
