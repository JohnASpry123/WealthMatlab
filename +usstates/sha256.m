function value = sha256(file)
fid = fopen(file,'rb');
assert(fid>=0,'usstates:File','Cannot read file for checksum.');
cleanup = onCleanup(@() fclose(fid));
digest = java.security.MessageDigest.getInstance('SHA-256');
while ~feof(fid)
    digest.update(fread(fid,1024*1024,'*uint8'));
end
value = lower(reshape(dec2hex(typecast(digest.digest(),'uint8'),2)',1,[]));
end
