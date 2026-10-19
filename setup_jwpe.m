function info = setup_jwpe()
%SETUP_JWPE Add this package's explicit folders to the current MATLAB session.
% No model, optimizer or statistical analysis is executed. No permanent path edit.
root=fileparts(mfilename('fullpath'));
assert(~verLessThan('matlab','9.13'),'JWPE:Setup:Version','MATLAB R2022b or later is required.');
folders={'src/kernels','analyses','examples','src/api'};
for k=1:numel(folders),addpath(fullfile(root,folders{k}),'-begin');end
info=jwpe_package_info();
assert(strcmpi(which('setup_jwpe'),fullfile(root,'setup_jwpe.m')), ...
    'JWPE:Setup:Shadow','Another package shadows setup_jwpe.');
end
