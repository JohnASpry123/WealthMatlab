function [file, record] = cachedDownload(url, file, offline, beaYears)
% Cache verified bytes with provenance. BEA response credentials are removed.
if nargin<4, beaYears=[]; end
sidecar = [file '.json'];
if isfile(file)
    assert(isfile(sidecar),'usstates:Cache','Cache sidecar missing: %s',sidecar);
    record = jsondecode(fileread(sidecar));
    assert(strcmp(record.url,url) && strcmp(record.sha256,usstates.sha256(file)), ...
        'usstates:Cache','Cache provenance/hash mismatch: %s. Use a new cache directory.',file);
    if ~isempty(beaYears)
        assert(strcmp(record.years,usstates.yearList(beaYears)), ...
            'usstates:Cache','Cached BEA year request differs.');
    end
    return
end
assert(~offline,'usstates:Offline','Offline cache missing: %s',file);
folder = fileparts(file);
if ~isfolder(folder), mkdir(folder); end
temp = [tempname(folder) '.download'];
cleanup = onCleanup(@() removeTemporary(temp));
if isempty(beaYears)
    websave(temp,url,weboptions('Timeout',120));
else
    key = getenv('BEA_API_KEY');
    assert(~isempty(key),'usstates:BEAKey', ...
        'Set BEA_API_KEY to an active registered key; sampleUser does not work.');
    try
        raw = webread(url,'UserID',key,'method','GetData','datasetname','Regional', ...
            'TableName','SAGDP9N','LineCode','1','GeoFIPS','STATE', ...
            'Year',usstates.yearList(beaYears),'ResultFormat','JSON',weboptions('Timeout',120));
    catch
        error('usstates:BEANetwork','BEA download failed. Check connectivity and your registered API key.');
    end
    usstates.parseBEA(raw,beaYears);
    if isfield(raw.BEAAPI,'Request'), raw.BEAAPI=rmfield(raw.BEAAPI,'Request'); end
    fid=fopen(temp,'w'); assert(fid>=0,'usstates:File','Cannot write cache.');
    c=onCleanup(@() fclose(fid)); fwrite(fid,jsonencode(raw),'char'); clear c
end
record=struct('url',url,'retrievedUTC',char(datetime('now','TimeZone','UTC')), ...
    'sha256',usstates.sha256(temp));
if ~isempty(beaYears)
    record.years=usstates.yearList(beaYears);
    record.table='SAGDP9N'; record.line=1;
end
movefile(temp,file);
fid=fopen(sidecar,'w'); assert(fid>=0,'usstates:File','Cannot write cache metadata.');
c=onCleanup(@() fclose(fid)); fwrite(fid,jsonencode(record),'char');
end

function removeTemporary(file)
if isfile(file), delete(file); end
end
