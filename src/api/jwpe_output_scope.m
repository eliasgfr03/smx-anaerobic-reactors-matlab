function previous=jwpe_output_scope(value)
%JWPE_OUTPUT_SCOPE Process-local write root for the active execution.
persistent current
if isempty(current),current='';end
previous=current;
if nargin==1,current=value;end
end
