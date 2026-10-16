function tests = testUSStates
tests = functiontests(localfunctions);
end

function testGrowthIsolation(t)
verifyEqual(t,growth([100;110;99]),[.1;-.1],'AbsTol',1e-14);
verifyEqual(t,usstates.logGrowth([100 110 99]),[log(1.1);log(.9)],'AbsTol',1e-14);
verifyError(t,@() usstates.logGrowth(1),'usstates:Sample');
end

function testYearListRegression(t)
verifyEqual(t,usstates.yearList((1997:2025)'),strjoin(arrayfun(@num2str,1997:2025,'UniformOutput',false),','));
verifyEqual(t,usstates.yearList(1997),'1997');
verifyError(t,@() usstates.yearList([1997;1999]),'usstates:Years');
end

function testTieRanks(t)
verifyEqual(t,usstates.rankDescending([3;1;3;2]),[1.5;4;1.5;3]);
verifyEqual(t,usstates.rankDescending(ones(50,1)),25.5*ones(50,1));
end

function testBEAUnitsAndFIPS(t)
r=beaFixture(); r.BEAAPI.Results.Data(1).GeoName='Name with footnote *';
g=usstates.parseBEA(r,[1997;1998]);
verifyEqual(t,height(g),100);
verifyEqual(t,g.Y(1),1000e6);
verifyFalse(t,any(ismember(g.fips,[0 11 72 91])));
end

function testBEAMissingAndDuplicate(t)
r=beaFixture(); r.BEAAPI.Results.Data(1)=[];
verifyError(t,@() usstates.parseBEA(r,[1997;1998]),'usstates:Coverage');
r=beaFixture(); r.BEAAPI.Results.Data(end+1)=r.BEAAPI.Results.Data(1);
verifyError(t,@() usstates.parseBEA(r,[1997;1998]),'usstates:Coverage');
end

function testBEARejectsInvalidUnitsAndQuarter(t)
r=beaFixture(); r.BEAAPI.Results.Data(1).UNIT_MULT='3';
verifyError(t,@() usstates.parseBEA(r,[1997;1998]),'usstates:BEAUnits');
r=beaFixture(); r.BEAAPI.Results.Data(1).TimePeriod='1997Q1';
verifyError(t,@() usstates.parseBEA(r,[1997;1998]),'usstates:BEAFrequency');
r=beaFixture(); r.BEAAPI.Results.Data(1).Code='SAGDP2N-1';
verifyError(t,@() usstates.parseBEA(r,[1997;1998]),'usstates:BEASeries');
end

function testBEARejectsSuppression(t)
r=beaFixture(); r.BEAAPI.Results.Data(1).DataValue='(D)';
verifyError(t,@() usstates.parseBEA(r,[1997;1998]),'usstates:Values');
r.BEAAPI.Results=struct('Error',struct('APIErrorCode','4'));
verifyError(t,@() usstates.parseBEA(r,[1997;1998]),'usstates:BEAResponse');
end

function testAssemblyAndGrowthIdentities(t)
d=panelFixture();
verifyEqual(t,d.Alabama.y_pop,[1e6;1.2e6],'AbsTol',1e-8);
s=usstates.summarize(d);
verifyEqual(t,s.g_y_pop,s.g_Y-s.g_pop,'AbsTol',1e-13);
verifyEqual(t,s.g_y_w,s.g_Y-s.g_pop_w,'AbsTol',1e-13);
verifyEqual(t,s.g_y_pop,repmat(log(1.2),50,1),'AbsTol',1e-13);
verifyEqual(t,s.n_intervals,ones(50,1));
verifyEqual(t,s.rank_g_y_pop,repmat(25.5,50,1));
end

function testRejectBadPanel(t)
d=panelFixture(); d=rmfield(d,'Alabama');
verifyError(t,@() usstates.summarize(d),'usstates:States');
d=panelFixture(); d.Alabama.year=[1997;1999];
verifyError(t,@() usstates.validatePanel(d),'usstates:Years');
d=panelFixture(); d.Alaska.year=[1997;1999];
verifyError(t,@() usstates.validatePanel(d),'usstates:Alignment');
d=panelFixture(); d.Alabama.pop_w(1)=2000;
verifyError(t,@() usstates.validatePanel(d),'usstates:Population');
d=panelFixture(); d.Alabama.y_pop(1)=1;
verifyError(t,@() usstates.validatePanel(d),'usstates:Identity');
d=panelFixture(); d.Alabama.Y(1)=NaN;
verifyError(t,@() usstates.validatePanel(d),'usstates:Values');
end

function testCensusAgeBoundaryAndNoDoubleCounting(t)
[folder,c]=tempFolder(); %#ok<ASGLU>
f=fullfile(folder,'ages.csv'); a=censusFixture('alldata6');
% Non-total sex and origin rows must not be added to resident totals.
b=a(1,:); b.SEX=1; b.POPESTIMATE2025=1e9; a=[a;b];
b.SEX=0; b.ORIGIN=1; a=[a;b];
writetable(a,f); p=usstates.parseCensus(f,'alldata6',2025);
verifyEqual(t,p.pop,86*6*10*ones(50,1));
verifyEqual(t,p.pop_w,50*6*10*ones(50,1));
end

function testCensusMissingAndDuplicateAge(t)
[folder,c]=tempFolder(); %#ok<ASGLU>
f=fullfile(folder,'ages.csv'); a=censusFixture('alldata6');
writetable(a(2:end,:),f);
verifyError(t,@() usstates.parseCensus(f,'alldata6',2025),'usstates:CensusCoverage');
writetable([a;a(1,:)],f);
verifyError(t,@() usstates.parseCensus(f,'alldata6',2025),'usstates:CensusCoverage');
end

function testIntercensalTotalReconciliation(t)
[folder,c]=tempFolder(); %#ok<ASGLU>
f=fullfile(folder,'ages.csv'); a=censusFixture('intercensal2000');
writetable(a,f); p=usstates.parseCensus(f,'intercensal2000',2000);
verifyEqual(t,p.pop_w,500*ones(50,1));
a.POPESTIMATE2000(a.AGE==999)=1;
writetable(a,f);
verifyError(t,@() usstates.parseCensus(f,'intercensal2000',2000),'usstates:CensusTotal');
end

function testHistoricalAgeGroups(t)
[folder,c]=tempFolder(); %#ok<ASGLU>
f=fullfile(folder,'1997.txt');
[s,a,r,h]=ndgrid(usstates.states(),0:18,1:8,1:2);
x=[97*ones(numel(s),1),s(:)*1000+1,a(:),r(:),h(:),10*ones(numel(s),1)];
fid=fopen(f,'w'); fprintf(fid,'%d %05d %d %d %d %d\n',x'); fclose(fid);
p=usstates.parseCensus(f,'intercensal1990',1997);
verifyEqual(t,p.pop,19*8*2*10*ones(50,1));
verifyEqual(t,p.pop_w,10*8*2*10*ones(50,1));
fid=fopen(f,'a'); fprintf(fid,'%d %05d %d %d %d %d\n',x(1,:)'); fclose(fid);
verifyError(t,@() usstates.parseCensus(f,'intercensal1990',1997),'usstates:CensusDuplicate');
end

function testLoaderCoverageAndLegacy(t)
[folder,c]=tempFolder(); %#ok<ASGLU>
f=fullfile(folder,'panel.mat'); data=panelFixture(); metadata=metadataFixture();
save(f,'data','metadata');
[d,m]=ReadDataUSStates(1998,inf,f);
verifyEqual(t,d.Alabama.year,1998); verifyEqual(t,m.analysisEndYear,1998);
verifyError(t,@() ReadDataUSStates(1997,1999,f),'usstates:Coverage');
verifyError(t,@() usstates.summarize(d),'usstates:Sample');
save(f,'data');
verifyError(t,@() ReadDataUSStates(1997,1998,f),'usstates:Schema');
end

function testOfflineCacheAndTampering(t)
[folder,c]=tempFolder(); %#ok<ASGLU>
f=fullfile(folder,'raw.txt');
verifyError(t,@() usstates.cachedDownload('fixture',f,true),'usstates:Offline');
fid=fopen(f,'w'); fwrite(fid,'abc'); fclose(fid);
verifyEqual(t,usstates.sha256(f),'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad');
record=struct('url','fixture','sha256',usstates.sha256(f),'retrievedUTC','fixture');
fid=fopen([f '.json'],'w'); fwrite(fid,jsonencode(record)); fclose(fid);
[file,~]=usstates.cachedDownload('fixture',f,true); verifyEqual(t,file,f);
fid=fopen(f,'a'); fwrite(fid,'changed'); fclose(fid);
verifyError(t,@() usstates.cachedDownload('fixture',f,true),'usstates:Cache');
end

function testOfflineOutputAndPlots(t)
[folder,c]=tempFolder(); %#ok<ASGLU>
f=fullfile(folder,'panel.mat'); data=panelFixture(); metadata=metadataFixture();
save(f,'data','metadata'); out=fullfile(folder,'results');
s=Main_USStates(1997,1998,f,out,true);
verifyEqual(t,height(s),50);
files={'USStates_AverageGrowth.csv','USStates_AverageGrowth.mat','USStates_RunMetadata.json', ...
    'USStates_IndexPlots.png','USStates_RankScatter.png','USStates_RankDiffHistogram.png'};
for i=1:numel(files), verifyTrue(t,isfile(fullfile(out,files{i}))); end
r=readtable(fullfile(out,files{1})); verifyEqual(t,r.g_y_pop,s.g_y_pop,'AbsTol',1e-12);
end

function testCompleteOfflineBuild(t)
[folder,c]=tempFolder(); %#ok<ASGLU>
cache=fullfile(folder,'cache'); mkdir(cache);
popFile=fullfile(cache,'st-est00int-agesex.csv');
a=censusFixture('intercensal2000'); a.POPESTIMATE2001=a.POPESTIMATE2000;
writetable(a,popFile);
url='https://www2.census.gov/programs-surveys/popest/datasets/2000-2010/intercensal/state/st-est00int-agesex.csv';
writeSidecar(popFile,url,'');
r=beaFixture();
for i=1:numel(r.BEAAPI.Results.Data)
    r.BEAAPI.Results.Data(i).TimePeriod=num2str(str2double(r.BEAAPI.Results.Data(i).TimePeriod)+3);
end
beaFile=fullfile(cache,'bea_SAGDP9N_1_2000_2001.json');
fid=fopen(beaFile,'w'); fwrite(fid,jsonencode(r)); fclose(fid);
writeSidecar(beaFile,'https://apps.bea.gov/api/data','2000,2001');
out=fullfile(folder,'nested','panel.mat');
[d,m]=BuildUSStateDataset(2000,2001,out,cache,true);
verifyEqual(t,numel(fieldnames(d)),50); verifyEqual(t,m.schemaVersion,2);
[reloaded,~]=ReadDataUSStates(2000,2001,out);
verifyEqual(t,reloaded,d);
s=Main_USStates(2000,2001,out,fullfile(folder,'results'),false);
verifyEqual(t,s.g_Y,zeros(50,1));
end

function writeSidecar(file,url,years)
record=struct('url',url,'years',years,'sha256',usstates.sha256(file),'retrievedUTC','synthetic fixture');
fid=fopen([file '.json'],'w'); fwrite(fid,jsonencode(record)); fclose(fid);
end

function r=beaFixture()
[f,~]=usstates.states(); rows=struct([]); k=0;
for y=1997:1998
    for i=1:50
        k=k+1;
        rows(k)=struct('GeoFIPS',sprintf('%02d000',f(i)),'GeoName','unused', ...
            'TimePeriod',num2str(y),'DataValue','1,000','CL_UNIT','Millions of chained 2017 dollars', ...
            'UNIT_MULT','6','Code','SAGDP9N-1'); %#ok<AGROW>
    end
end
for geo={'00000','11000','72000','91000'}
    row=rows(1); row.GeoFIPS=geo{1}; rows(end+1)=row; %#ok<AGROW>
end
r=struct('BEAAPI',struct('Results',struct('Data',rows)));
end

function d=panelFixture()
[f,y]=ndgrid(usstates.states(),[1997;1998]);
g=table(f(:),y(:),1e9*(1+.2*(y(:)-1997)),'VariableNames',{'fips','year','Y'});
p=table(f(:),y(:),1000*ones(numel(f),1),600*ones(numel(f),1), ...
    'VariableNames',{'fips','year','pop','pop_w'});
% Deliberately different source row order; join must use FIPS/year.
d=usstates.assemble(g(end:-1:1,:),p,[1997;1998]);
end

function a=censusFixture(kind)
if strcmp(kind,'alldata6')
    [s,age,r]=ndgrid(usstates.states(),0:85,1:6); n=numel(s);
    a=table(40*ones(n,1),s(:),zeros(n,1),zeros(n,1),r(:),age(:),10*ones(n,1), ...
        'VariableNames',{'SUMLEV','STATE','SEX','ORIGIN','RACE','AGE','POPESTIMATE2025'});
else
    [s,age]=ndgrid(usstates.states(),[0:85 999]); n=numel(s); x=10*ones(n,1); x(age(:)==999)=860;
    a=table(s(:),zeros(n,1),age(:),x,'VariableNames',{'STATE','SEX','AGE','POPESTIMATE2000'});
end
end

function m=metadataFixture()
m=struct('schemaVersion',2,'startYear',1997,'endYear',1998, ...
    'gdpUnits','chained 2017 dollars','workingAge','15-64 inclusive');
end

function [folder,c]=tempFolder()
folder=tempname; mkdir(folder); c=onCleanup(@() rmdir(folder,'s'));
end
