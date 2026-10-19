function [hit,value,index,key] = ppu_cache_v1(reactor,theta,identity,keys,values)
%PPU_CACHE_V1 Exact task-local full-trajectory cache lookup.

assert(any(strcmp(reactor,{'CS','PF'})) && contains(identity,reactor), ...
    'JWPE:PPU:Cache','Cross-reactor or unbound cache identity.');
text=[identity '|' sprintf('%.17g,',theta)];
key=ppu_io_v1('hash',text,'text'); index=find(strcmp(keys,key));
assert(numel(index)<=1,'JWPE:PPU:Cache','Duplicate cache identity.');
hit=isscalar(index);
if hit, value=values(index,:); else, value=[]; index=0; end
end
