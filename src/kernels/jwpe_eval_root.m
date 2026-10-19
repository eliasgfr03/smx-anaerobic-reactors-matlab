function root=jwpe_eval_root()
%JWPE_EVAL_ROOT Resolve the independent package, without calling science.
root=fileparts(fileparts(fileparts(mfilename('fullpath'))));
end
