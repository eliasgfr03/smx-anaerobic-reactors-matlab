function hex = m1_hash_v1(value,kind)
% Empty input needs no update: MATLAB empties have ambiguous Java conversion.
kind=lower(string(kind));
switch kind
    case "file"
        fid=fopen(char(value),'rb'); assert(fid>=0,'JWPE:Persist:File','Cannot open input.');
        closer=onCleanup(@()fclose(fid)); assert(isa(closer,'onCleanup'));
        bytes=fread(fid,Inf,'*uint8');
    case "text"
        bytes=uint8(unicode2native(char(string(value)),'UTF-8')); bytes=bytes(:);
    case "bytes"
        bytes=uint8(value(:));
    otherwise
        error('JWPE:Persist:Kind','Unsupported hash input kind.');
end
md=java.security.MessageDigest.getInstance('SHA-256');
if ~isempty(bytes), md.update(typecast(bytes,'int8')); end
digest=typecast(md.digest(),'uint8');
hex=lower(reshape(dec2hex(digest,2).',1,[]));
end
