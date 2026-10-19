function key = jwpe_calibration_key(theta)
%JWPE_CALIBRATION_KEY Preserve the source's 17-digit exact theta encoding.
%   One cache belongs to one immutable run/context/configuration only.
theta = double(theta(:).');
assert(numel(theta)==5 && all(isfinite(theta)), ...
    'JWPE:Public:Cache','Expected five finite native M1 parameters.');
key = sprintf('%.17g,',theta);
end
