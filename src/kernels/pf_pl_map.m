function theta=pf_pl_map(x,cfg)
%PF_PL_MAP Reuse exact source maps, including four-coordinate corners.
x=double(x(:).');
assert(numel(x)==cfg.config.nvar && all(isfinite(x)),'PFPort:Map','Malformed nuisance vector.');
switch cfg.map
    case 'p12'
        theta=pf_p12_map(x,cfg.spec);
    case 'r1'
        theta=plr1_map(x,cfg.spec);
    case 'r11'
        theta=plr11_map(x,cfg.spec);
    case 'fixed_ksigma'
        ks=cfg.fixedValue;
        % Exact source local_full_search + search_to_native for the reused probe.
        theta=[x(1),ks*x(2),ks*(1-x(2)),x(3),x(4),x(5)];
    otherwise
        error('PFPort:Map','Unimplemented source mapping.');
end
assert(numel(theta)==6 && all(isfinite(theta)),'PFPort:Map','Malformed native vector.');
end
