function openRecent_CALLBACK(src,evnt,guiObjects)
%openRecent_CALLBACK.m This function is a callback for the open recent button on the
%Cell gui which opens up a list of mice and opens the most recent file

%get most up to date guiObjects
guiObjects = get(guiObjects.figHandle,'UserData');

%change to data directory
origDir = cd(guiObjects.userData.path);

%cycle through each folder (current, archived, etc.)
animals = cell(1,length(guiObjects.userData.folders));
numAn = 0;
for i=1:length(guiObjects.userData.folders)
    dataDir = fullfile(guiObjects.userData.path,guiObjects.userData.folders{i});
    if exist(dataDir,'dir');
        pathDir = cd(fullfile(guiObjects.userData.path,guiObjects.userData.folders{i})); %change to current/archived folder
        
        folderList = dir([guiObjects.userData.initials,'*']); %get list of animals (starting with user initials)
        
        %convert to cell
        animals{i} = struct2cell(folderList); %convert structure to cell
        animals{i} = animals{i}(1,:); %only take names
        
        %count animals
        numAn = numAn + length(animals{i});
        
        cd(pathDir); %change back to path directory
    end
end

%generate tableData
tableData = cell(0,2);
for i=1:length(animals)
    origSize = size(tableData,1);
    tableData(origSize+1:origSize+length(animals{i}),1) =...
        {guiObjects.userData.folders{i}};
    tableData(origSize+1:origSize+length(animals{i}),2) =...
        animals{i}';
end

%create table
anFig = figure('Name','Select Animal','NumberTitle','Off','MenuBar','none');
screens = get(0,'MonitorPositions');
if size(screens,1) > 1
    scrn = screens(2,:);
else
    scrn = screens(1,:);
end
set(anFig,'OuterPosition',[scrn(1)+0.5*(scrn(3)-scrn(1)) scrn(2)...
    0.2*(scrn(3)-scrn(1)) scrn(4)]); %set position
tableHandle = uitable;
set(tableHandle,'Units','Normalized','Position',[0.025 0.01 0.95 0.98],'Data',tableData,...
    'ColumnWidth',{170 120},'ColumnName',{'Root','Mouse'},'CellSelectionCallback',...
    {@rowSelect_CALLBACK,guiObjects,tableData,anFig},'FontSize',18);

%change back to original directory
cd(origDir);
end

function rowSelect_CALLBACK(src,evnt,guiObjects,tableData,anFig)
%change to folder
origDir = cd(fullfile(guiObjects.userData.path,...
    tableData{evnt.Indices(1),1},tableData{evnt.Indices(1),2}));

%get list of files
try
    fileList = dir('*_Cell.mat');
    recFile = fileList(end).name;
    filePath = fullfile(guiObjects.userData.path,...
        tableData{evnt.Indices(1),1},tableData{evnt.Indices(1),2},recFile);
catch
   cd(origDir);
   errordlg('No Cell File Found');
   return;
end

%call openCellFiles_Callback
openCellFiles_CALLBACK(src,evnt,guiObjects,true,filePath,false,false)

%close fig
close(anFig);

%change back to original directory
cd(origDir);
end