function [ephysData, fileNames] = packageOpenEphysData(dirname)
%Created 2015-02-04 by J. Sy 
%Here we're going to take the load_open_ephys_data function and use it
%to create an array containing all of the data from every channel in
%a file. This might be useful for... something, I hope. 

cd(dirname) 

fileList = dir([dirname '\*continuous']);
fileNames = {fileList.name};

ephysData = cell(numel(fileNames), 3); % First column is row number, second column is file name, third column is structure
for i = 1:numel(fileNames) 
    [data, timestamps, info] = load_open_ephys_data(fileNames{i});
    packageDIT = struct('name',fileNames{i},'data',data,'timestamps',timestamps,'info',info); %Put everything into a structure array
    channelPackage = packageDIT;
    ephysData{i,3} = channelPackage;
    ephysData{i,2} = fileNames{i};
    ephysData{i,1} = i;
end 

