function selected = gsa_ks_v1(X,ranges,k,originalIndex)
%GSA_KS_V1 Deterministic Kennard-Stone selection without consulting outputs.

X = double(X); ranges = double(ranges);
if nargin<4; originalIndex = (1:size(X,1)).'; end
originalIndex = double(originalIndex(:));
assert(size(X,2)==6 && size(ranges,1)==6 && size(ranges,2)==3, ...
    'JWPE:GSA:Dimension','Kennard-Stone input dimensions are invalid.');
assert(numel(originalIndex)==size(X,1) && numel(unique(originalIndex))==numel(originalIndex), ...
    'JWPE:GSA:Dimension','Original indices must be unique.');
assert(k>=2 && k<=size(X,1),'JWPE:GSA:Dimension','Invalid QA selection count.');

lo = ranges(:,1).'; hi = ranges(:,3).';
Z = (X-lo)./(hi-lo);
assert(all(isfinite(Z),'all') && all(Z>=-1e-12 & Z<=1+1e-12,'all'), ...
    'JWPE:GSA:Mapping','Normalized QA coordinates escaped [0,1].');

best = -inf; pair = [0 0]; n = size(Z,1);
for i=1:n-1
    d2 = sum((Z(i+1:end,:)-Z(i,:)).^2,2);
    localMax = max(d2); jCandidates = find(d2==localMax);
    [~,jj] = min(originalIndex(i+jCandidates));
    j = i+jCandidates(jj);
    if localMax>best || (localMax==best && ...
            local_pair_less(originalIndex([i j]),originalIndex(pair)))
        best = localMax; pair = [i j];
    end
end
[~,ord] = sort(originalIndex(pair)); selectedLocal = pair(ord);
minD2 = min(local_dist2(Z,Z(selectedLocal,:)),[],2);
minD2(selectedLocal) = -inf;
while numel(selectedLocal)<k
    mx = max(minD2); candidates = find(minD2==mx);
    [~,q] = min(originalIndex(candidates)); pick = candidates(q);
    selectedLocal(end+1) = pick; %#ok<AGROW>
    minD2 = min(minD2,sum((Z-Z(pick,:)).^2,2));
    minD2(selectedLocal) = -inf;
end
selected = originalIndex(selectedLocal(:));
end

function D = local_dist2(A,B)
D = zeros(size(A,1),size(B,1));
for j=1:size(B,1); D(:,j)=sum((A-B(j,:)).^2,2); end
end

function tf = local_pair_less(a,b)
if any(b==0); tf=true; return; end
a=sort(a); b=sort(b); tf=a(1)<b(1) || (a(1)==b(1) && a(2)<b(2));
end
