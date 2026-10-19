function cases=jwpe_pl_cases(model,reactor)
%JWPE_PL_CASES Read method-only fixed-coordinate recipes; never run a profile.
assert(ismember(string(model),["M0","M1_FREE","M1_FIXED"]) && ...
    ismember(string(reactor),["CS","PF"]));
info=jwpe_package_info();name=char(model);
if strcmp(name,'M0'),name=[name '_' char(reactor)];end
value=jsondecode(fileread(fullfile(info.packageRoot,'analyses','recipes',[name '.json'])));
cases=value.cases;
if isfield(cases,'reactor'),cases=cases(strcmp({cases.reactor},reactor));end
end
