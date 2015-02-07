function edgeAnalysis(pathDir, fileIndex);

startFileIndex = fileIndex(1); % Which file in the directory list do we start with?
endFileIndex   = fileIndex(2); % Which file in the directory list do we end with?

% Open a series of files, channel by channel
chNum        = 32;
freqSampling = 19531 ;
samplesPerChunk = chNum*freqSampling*30;
badChannels = [];

%% Define Filters
% LFP filter
orderButter     = 2;
ftype           = 'bandpass';
freqLow         = 0.5;
freqHigh        = 100;
Wn              = [2*freqLow/freqSampling 2*freqHigh/freqSampling];
[z, p, k]       = butter(orderButter,Wn,ftype);
[sos,g]         = zp2sos(z,p,k);
bandPassFilter  = dfilt.df2sos(sos,g);
[b_LFP,a_LFP]   = sos2tf(sos,g);

% Spike filter
orderButter  = 4;
ftype        = 'high';
freqLow      = 300;
Wn           = [2*freqLow/freqSampling];

[z, p, k]    = butter(orderButter,Wn,ftype);
[sos,g]      = zp2sos(z,p,k);
bandPassFilter = dfilt.df2sos(sos,g);
[b,a]          = sos2tf(sos,g);

%% Map Electrodes

IntanToNeuralynx = [32 30 31 28 29 26 27 24 25 22 23 21 20 19 18 17 11  9  7  5  3  1  2  4  6  8 10 12 13 14 15 16]; %First channel (as in the files) from SGL to the Probes
%AndrewTo32x1     = [17 16 18 15 19 14 20 13 21 12 22 11 23 10 24  9 25  8 26  7 27  6 28  5 29  4 30  3 31  2 32  1]; % Electrode numbering in Probes to my reference (1 at top, 16 bottom)
Buz32ToIntan     = [1 8 2 7 3 6 4 5 9 16 10 15 11 14 12 13 17 24 18 23 19 22 20 21 25 32 26 31 27 30 28 29]; % Electrode numbering in Probes to my reference (1 at top, 16 bottom)
inverseConnection =      [8 6 7 3 5 1 4 26  2 30 28 32 25 27 29 31 18 20 22 24 17  9 19 10 21 11 23 12 15 14 16 13];
forwardConnection =       [6  9  4  7  5  2  3  1 22 24 26 28 32 30 29 31 21 17 23 18 25 19 27 20 13  8 14 11 15 10 16 12];
for i=1:32,
    IntanToBuz32(i) = find (IntanToNeuralynx == Buz32ToIntan(i));
    InverseIntanToBuz32 (find (IntanToNeuralynx == Buz32ToIntan(i))) = i;
end


%% Reading

%pathDir    = [pwd '/']%'/Lab/Silicon/ANM144443/110811/';
d          = dir([pathDir '*.bin']);
fileList   = cell(length(d),1);
for i = 1:length(d);
    fileList{i}=d(i).name;
end
%startFileIndex = 1; % Which file in the directory list do we start with?
%endFileIndex   = 266; % Which file in the directory list do we end with?

%% Create initial timestamp
% Timestamps are uint32, starting with the hour/minute/second of the first
% file processed
% timestamp of the first timepoint in the first file
% timestamps are initialized based on the modification time of each .bin
% file. If the recordings finish and end less than 1 second apart,
% timestamps may overlap, breaking the code.

initialtime=datevec(d(startFileIndex).date); % JS: Don't need this portion. 
initialtime=uint32((initialtime(4)*60*60+initialtime(5)*60+initialtime(6))*freqSampling); % convert first file timestamp to uint32 stamp
spkdata=[];
spikeDetectInput=struct;

for fnum = startFileIndex:endFileIndex%1:length(d);
    tic
    fid = fopen([pathDir fileList{fnum}],'r');
    spikeDetectInput.y = [];


    % Read data from file, minute by minute
    fileChunks = ceil(d(fnum).bytes/(samplesPerChunk*2));  % How many reads of the file do we do?

    for i = 1:fileChunks 
        display(['Reading ' d(fnum).name ' / Chunk ' num2str(i)])
        fid      = fopen([pathDir fileList{fnum}],'r');
        fileTime = datevec(d(fnum).date);
        fileTime = uint32((fileTime(4)*60*60+fileTime(5)*60+fileTime(6))*freqSampling); % convert file timestamp to uint32 stamp

        % set readpoint of file
        startPointer = (i-1)*(samplesPerChunk)*2;     
        fileStatus   = fseek(fid,startPointer,-1);  

        if startPointer + (samplesPerChunk)*2 < d(fnum).bytes;
            matrixRaw = fread(fid,samplesPerChunk,'uint16'); % Read a full chunk
        else
        matrixRaw = fread(fid,samplesPerChunk,'uint16'); % Read till file end
        end
        
    end

    st=fclose('all');

    matrixVol=double(10*(matrixRaw-(sign(matrixRaw-2^15)+1)*2^15)/2^16); % Convert to doubles and scale voltage
    clear matrixRaw
    ch=reshape(matrixVol,chNum,size(matrixVol,1)/chNum)';
    clear matrixVol
    ch(:,forwardConnection)=ch(:,1:32);

    %filteredData = filtfilt(b,a,ch);e
    % Notch filters
    chNotch     = zeros(size(ch,1),32);
    y           = zeros(size(ch,1),32);
    filteredLFP = zeros(size(ch,1),32);    
 filetime = 0; % JS: Generally used to set up time stamps
       for j=1:32
            ch1             = timeseries(ch(:,j),0:1/freqSampling:(length(ch(:,j))-1)/freqSampling);
    %         ch_60           = idealfilter(ch1,[59 61.5],'notch');
    %         ch_120          = idealfilter(ch_60,[119 122],'notch');
    %         ch_180          = idealfilter(ch_120,[178 183],'notch');
    %         chNotch(:,j)    = ch_180.data;
            chSpike         = idealfilter(ch1,[300 6000],'pass');
    %         chLFP           = idealfilter(ch_180,[0.5 200],'pass');
            spikeDetectInput.y(:,j) = chSpike.data;
            
    %         filteredLFP(:,j)= chLFP.data;
       end
    temp                 = sort(spikeDetectInput.y,2);
    spikeDetectInput.emg = mean(temp(:,9:24),2); 
    spikeDetectInput.y   = spikeDetectInput.y - repmat(spikeDetectInput.emg,1,32);
            
    spikeDetectInput.y(:,badChannels) = zeros(size(spikeDetectInput.y(:,badChannels)));
    
    spikeDetectInput.timeStamps = fileTime:fileTime+size(y,1);
    
    spikeDetectOutput = spkDetectEdge(spikeDetectInput);



     targetDir = [pathDir 'extract/'];

     for i = 1
         filedata.waves = spikeDetectOutput{i}.shiftspikes;
         filedata.timestamps = spikeDetectOutput{i}.timestamps;
         filedata.params = spikeDetectOutput{i}.params;
         filedata.paramnames = spikeDetectOutput{i}.paramnames;
         filedata.filename = [d(fnum).name 'shank' num2str(i)];

         save([targetDir d(fnum).name 'shank' num2str(i)], 'filedata');

     end
    toc 
end
    
  
 
 
 
% %% Define spike export info
% display('exporting data')
% pathDir = '/Lab/Silicon/Busaki32Test/';
% targetDir = '/Lab/Silicon/Busaki32Test/';
% mkdir(targetDir,'extracted/temp/');
% depth=1;
% % N_files = length(fileList);
% % groupList = unique(groups);
% % N_groups  = length(groupList);
% actualFileName = fileList{fnum};
%     for j=1:32,
%         spk = data{j};
%         LFP = LFPAll(:,j);
%         raw = ch(:,j);
%         rawSpikes = y(:,j);
%         saveDataSpikesForLoop (pathDir,actualFileName,spk,j,depth,i);
%         saveDataLFPForLoop (pathDir,actualFileName,LFP,j,depth,i);
%         saveDataRawForLoop (pathDir,actualFileName,raw,j,depth,i);
%         saveDataRawSpikesForLoop (pathDir,actualFileName,rawSpikes,j,depth,i);
%     end
%     


