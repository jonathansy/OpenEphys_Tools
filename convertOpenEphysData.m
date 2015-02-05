%% Takes the .continuous files genered by open ephys and converts them to structure arrays of the same name
%Created 2015-02-05 by J. Sy
%Dependencies: load_open_ephys_data.m (obtained through Github),
%ephysToArray.m 

%Note: Made to run on all files of a directory. Unlike
%packageOpenEphysData, everything should be separate 

channelDir = input('Please input the directory you wish to process','s'); 

fileList = dir([dirname '\*continuous']);
fileNames = {fileList.name};

for i = 1:numel(fileNames)
    [ephysOutput, channelName] = ephysToArray(fileNames(i));
    v = ephysOutput; 
    v = genvarname(channelName); 
end 
