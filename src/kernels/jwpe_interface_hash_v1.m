function hex = jwpe_interface_hash_v1(value,kind)
%JWPE_INTERFACE_HASH_V1 SHA256 I/O primitive adapted from m1_hash_v1.
% Same byte hashing algorithm; no numerical model/likelihood computation.
switch char(string(kind))
    case 'file'
        fid=fopen(char(value),'rb');assert(fid>=0,'JWPE:Interface:Hash','Cannot open file.');
        cleanup=onCleanup(@()fclose(fid));
        assert(isa(cleanup,'onCleanup'));bytes=fread(fid,Inf,'*uint8');
    case 'text'
        bytes=uint8(unicode2native(char(string(value)),'UTF-8'));bytes=bytes(:);
    otherwise
        error('JWPE:Interface:Hash','Unsupported hash kind.');
end
md=java.security.MessageDigest.getInstance('SHA-256');
if ~isempty(bytes),md.update(typecast(bytes,'int8'));end
digest=typecast(md.digest(),'uint8');
hex=lower(reshape(dec2hex(digest,2).',1,[]));
end
