function varargout = p3v_math_v1(action,varargin)
%P3V_MATH_V1 Frozen validation-layer and probabilistic score calculations.

switch lower(string(action))
    case "sigma"
        varargout{1}=sqrt(varargin{2}.^2+(varargin{3}.*varargin{1}).^2);
    case "pcens"
        varargout{1}=0.5*erfc(-((varargin{3}-varargin{1})./varargin{2})/sqrt(2));
    case "quantile"
        varargout{1}=ppu_math_v1('quantile',varargin{1},varargin{2});
    case "zerotolod"
        varargout{1}=local_lod(varargin{1},varargin{2});
    case "crps"
        varargout{1}=local_crps(varargin{1},varargin{2});
    otherwise
        error('JWPE:P3V:Math','Unsupported P3V math action.');
end
end

function validation=local_lod(raw,lod)
raw=double(raw(:));
assert(all(isfinite(raw)) && ~any(raw<0),'JWPE:P3V:Observation', ...
    'Negative or nonfinite holdout response.');
validation=raw; validation(raw==0)=lod;
assert(all(validation(raw>0)==raw(raw>0)) && all(validation(raw==0)==lod), ...
    'JWPE:P3V:Observation','Zero-to-LOD layer changed a positive observation.');
end

function value=local_crps(samples,observation)
samples=double(samples(:)); observation=double(observation);
assert(all(isfinite(samples)) && isscalar(observation) && isfinite(observation), ...
    'JWPE:P3V:CRPS','CRPS inputs must be finite.');
n=numel(samples); ordered=sort(samples);
weight=(2*(1:n).'-n-1);
pairTerm=sum(weight.*ordered)/(n^2);
value=mean(abs(samples-observation))-pairTerm;
end
