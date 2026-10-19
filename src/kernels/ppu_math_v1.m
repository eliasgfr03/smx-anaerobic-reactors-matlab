function varargout = ppu_math_v1(action,varargin)
%PPU_MATH_V1 Frozen error, censoring, quantile and descriptive calculations.

switch lower(string(action))
    case "sigma"
        mu=varargin{1}; sigmaA=varargin{2}; sigmaP=varargin{3};
        varargout{1}=sqrt(sigmaA.^2+(sigmaP.*mu).^2);
    case "pcens"
        mu=varargin{1}; sigma=varargin{2}; lod=varargin{3};
        varargout{1}=0.5*erfc(-((lod-mu)./sigma)/sqrt(2));
    case "quantile"
        varargout{1}=local_quantile(varargin{1},varargin{2});
    case "summary"
        varargout{1}=local_summary(varargin{1},varargin{2});
    case "represent"
        varargout{1}=local_represent(varargin{1},varargin{2},varargin{3});
    otherwise
        error('JWPE:PPU:Math','Unsupported math action.');
end
end

function q=local_quantile(x,p)
assert(isnumeric(x) && ismatrix(x) && all(isfinite(x),'all'), ...
    'JWPE:PPU:Quantile','Quantile input must be a finite matrix.');
n=size(x,1); sorted=sort(x,1); q=zeros(numel(p),size(x,2));
for k=1:numel(p)
    pos=(n-1)*p(k)+1; lo=floor(pos); hi=ceil(pos); w=pos-lo;
    if lo==hi, q(k,:)=sorted(lo,:);
    else, q(k,:)=(1-w)*sorted(lo,:)+w*sorted(hi,:);
    end
end
end

function T=local_summary(x,names)
q=local_quantile(x,[0.025 0.25 0.5 0.75 0.975]);
T=table(string(names(:)),mean(x,1).',std(x,0,1).',q(3,:).',q(1,:).', ...
    q(2,:).',q(4,:).',q(5,:).','VariableNames',{'Parameter','Mean','SD', ...
    'Median','Q025','Q25','Q75','Q975'});
end

function T=local_represent(fullRows,selectedRows,names)
a=local_summary(fullRows,names); b=local_summary(selectedRows,names);
T=[addvars(a,repmat("FULL",height(a),1),'Before',1,'NewVariableNames','Set'); ...
    addvars(b,repmat("SELECTED",height(b),1),'Before',1,'NewVariableNames','Set')];
end
