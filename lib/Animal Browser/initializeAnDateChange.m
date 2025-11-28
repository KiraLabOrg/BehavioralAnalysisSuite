function [guiObjects] = initializeAnDateChange(path,filenames,guiObjects)
%initializeAnDateChange.m Initialize animal and date browser
%
%This function initializes the animal and date browsers by finding all
%animals and dates and placing them in listboxes at top of GUI
%
%ASM 9/19/12

%get most up to date guiObjects
guiObjects = get(guiObjects.figHandle,'UserData');

if strfind(path,guiObjects.userData.folders{1}) ~= 0
    anPath = [guiObjects.userData.path];
    % anPath = [guiObjects.userData.path,guiObjects.userData.folders{1}];
    loadedPath = 0;
elseif strfind(path,guiObjects.userData.folders{2}) ~= 0
    anPath = [guiObjects.userData.path,guiObjects.userData.folders{2}];
    loadedPath = 1;
end
origDir = cd(fullfile(anPath,'Current Mice'));

%get date from filenames
if iscell(filenames)
    fileDate = filenames{end};
else
    fileDate = filenames;
end

%Get list of folders in directory
file_initials = fileDate(1:2);
guiObjects.userData.initials = file_initials;
folderList = dir([guiObjects.userData.initials,'*']); %get all folders 
for i=1:size(folderList,1) %for each folder
    if isempty(strfind(path,folderList(i).name)) %if not current animal, loop to next folder
        continue;
    end
    
    loadedAn = i;
    
    cd(folderList(i).name); %change to directory
    fileList = dir([guiObjects.userData.initials,'*Cell*.mat']); %list files with cell array
    fileCell = cell(1,length(fileList)); %initialize cell
    for j=1:length(fileList) %for each file
        fileCell{j} = fileList(j).name; %set equal to name
    end
    dateStrings = cell(1,length(fileCell)); %initialize dateStrings
    for j=1:length(fileCell) %for each file
        if ~isempty(strfind(fileCell{j},'Cell_')) %if file contains alternate flag
            undInd = strfind(fileCell{j},'_');
            dateStrings{j} = fileCell{j}([7:12,undInd(end):find(isstrprop(fileCell{j},'digit'),1,'last')]); %get date and alternate flag
        else
            dateStrings{j} = fileCell{j}(7:12); %get date
        end
        if strcmp(fileDate,fileCell{j})
            loadedDate = j;
        end
    end
end

%set up animal change section 
anNames = arrayfun(@(x) x.name,folderList,'UniformOutput',false);
anNames =  cellfun(@(x)[x,'|'],anNames,'UniformOutput',false);
anNames = strcat(anNames{:});
anNames = anNames(1:end-1);

%set strings
set(guiObjects.animalPopup,'String',anNames,'Value',loadedAn);
set(guiObjects.datePopup,'String',dateStrings,'Value',loadedDate);
set(guiObjects.mouseToggle,'Value',loadedPath);

%store current file in animal popup
fileInfo.anPath = anPath;
fileInfo.folderList = folderList;
fileInfo.loadedFolder = loadedAn;
fileInfo.fileCell = fileCell;
fileInfo.loadedFile = loadedDate;
set(guiObjects.animalPopup,'UserData',fileInfo); %store current file

%change back to original directory
cd(origDir);

