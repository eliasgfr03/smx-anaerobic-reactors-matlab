function varargout=jwpe_eval_io(action,varargin)
%JWPE_EVAL_IO Portable technical I/O; scientific readers keep their own guards.
switch lower(string(action))
 case "hash",varargout{1}=m1_hash_v1(varargin{1},varargin{2});
 case "readtable",varargout{1}=readtable(varargin{1},'TextType','string','VariableNamingRule','preserve');
 case "payload",q=load(varargin{1},'payload');varargout{1}=q.payload;
 case "time",varargout{1}=char(datetime('now','TimeZone','UTC','Format','yyyy-MM-dd''T''HH:mm:ssXXX'));
 case "logical"
  x=varargin{1};if islogical(x),varargout{1}=x;return,end
  if isnumeric(x),assert(all(x==0 | x==1,'all'));varargout{1}=logical(x);return,end
  x=lower(string(x));assert(all(ismember(x,["0","1","false","true"]),'all'));
  varargout{1}=x=="1" | x=="true";
 case {"atomic","write"}
  f=char(varargin{1});root=jwpe_output_scope();
  canonical=char(java.io.File(f).getCanonicalPath());
  assert(~isempty(root) && java.io.File(f).isAbsolute(), ...
      'JWPE:Public:Path','An explicit execution output scope is required.');
  root=char(java.io.File(root).getCanonicalPath());
  assert(startsWith(canonical,[root filesep],'IgnoreCase',true), ...
      'JWPE:Public:Path','Writes must stay inside the chosen execution folder.');
  replace=false;if numel(varargin)>=4,replace=varargin{4};end
  m1_atomic_v1(f,varargin{2},varargin{3},replace);
 otherwise,error('JWPE:Public:IO','Unsupported portable I/O action.');
end
end
