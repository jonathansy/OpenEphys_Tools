%% v0.2 of packageOpenEphysData
%It'll work this time, no really
%Created 2015-02-06 by J. Sy

function [ephysData, ephysTimestamps] = packageOpenEphysData(dirname)
cd(dirname) 

fileList = dir([dirname '\*continuous']);
nameList = {fileList.name};
fileNames = nameList;

ephysLength = load_open_ephys_data(fileNames{1});

ephysData = zeros(32, length(ephysLength));
ephysTimestamps = zeros(32, length(ephysLength));
for i = 1:numel(fileNames) 
    [data, timestamps] = load_open_ephys_data(fileNames{i});
    
    ephysData(i,:) = data;
    ephysTimestamps(i,:) = timestamps;
    
end 
