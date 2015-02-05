%% Takes a single file of binary data from open ephys and converts it into a MATLAB structure array
%Note: Unlike packageOpenEphysData.m, this will not put all the channels
%into one giant array
function [ephysOutput, channelName] = ephysToArray(channelFile) 
[data, timestamps, info] = load_open_ephys_data(channelFile);
ephysOutput = struct('data',data,'timestamps',timestamps,'info',info);
[pathstr, name] = fileparts(channelFile);
channelName = name;