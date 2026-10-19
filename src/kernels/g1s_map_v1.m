function out = g1s_map_v1(direction,value,reactor,cfg)
%G1S_MAP_V1 Exact z <-> [kb,kG,tinf,Ai] coordinate map.
reactor = char(upper(string(reactor)));
assert(ismember(reactor,{'CS','PF'}),'G1S:Reactor','CS or PF required.');
s = cfg.supports.(reactor); value = double(value(:).');
assert(numel(value)==4 && all(isfinite(value)),'G1S:Mapping','Four finite values required.');
switch lower(string(direction))
    case "decode"
        assert(all(value>=0 & value<=1),'G1S:Support','z outside [0,1].');
        kG=exp(log(s.kG(1))+value(2)*(log(s.kG(2))-log(s.kG(1))));
        if value(2)==0, kG=s.kG(1); elseif value(2)==1, kG=s.kG(2); end
        out = [s.kb(2)*value(1),kG, ...
            s.tinf(1)+(s.tinf(2)-s.tinf(1))*value(3), ...
            s.Ai(2)*value(4)];
    case "encode"
        assert(value(1)>=s.kb(1) && value(1)<=s.kb(2) && ...
            value(2)>=s.kG(1) && value(2)<=s.kG(2) && ...
            value(3)>=s.tinf(1) && value(3)<=s.tinf(2) && ...
            value(4)>=s.Ai(1) && value(4)<=s.Ai(2), ...
            'G1S:Support','Physical coordinate outside support.');
        out = [value(1)/s.kb(2), ...
            (log(value(2))-log(s.kG(1)))/(log(s.kG(2))-log(s.kG(1))), ...
            (value(3)-s.tinf(1))/(s.tinf(2)-s.tinf(1)), ...
            value(4)/s.Ai(2)];
    otherwise
        error('G1S:Mapping','Unknown mapping direction.');
end
out=double(out(:).');
if lower(string(direction))=="encode"
    out=min(max(out,0),1);
end
end
