function openCellFiles_CALLBACK(src,evnt,guiObjects,silent,fileToLoad,online,addFile)
%openCellFiles_CALLBACK.m This function is a callback for the open button on the
%Cell gui which opens up a browswer and passes cell data to the gui

%get most up to date guiObjects
guiObjects = get(guiObjects.figHandle,'UserData');

%turn off warnings
warning('off','MATLAB:loadobj');

if nargin < 7
    addFile = false;
end

if nargin < 6
    online = false; %if not specified declare online as false
end

if silent && ~online
    origDir = cd(guiObjects.userData.path); %change to data directory
    filepath = fileToLoad(1:regexp(fileToLoad,'\D\D\d\d\d_')-1);
    filenames = fileToLoad(regexp(fileToLoad,'\D\D\d\d\d_'):end);
elseif silent && online
    origDir = cd;
    filepath = fileToLoad(1:regexp(fileToLoad,[guiObjects.userData.tempName,'*'])-1);
    filenames = fileToLoad(regexp(fileToLoad,[guiObjects.userData.tempName,'*']):end);
else
    if ismac
        guiObjects.userData.path(strfind(guiObjects.userData.path,'\')) = '/';
        guiObjects.userData.path = guiObjects.userData.path(1:end);
        guiObjects.userData.path = [guiObjects.userData.path];
    end
    origDir = cd(guiObjects.userData.path); %change to data directory
    if addFile %if addFile display list of old files
        info = get(guiObjects.openSelected,'UserData');
        listGUI = listFiles(info.filenames);
    end
    [filenames,filepath]=uigetfile({'*_Cell*.mat','Cell Files'},'Select file(s)','MultiSelect','on'); %get file names
    if addFile %close fileList
        close(listGUI);
    end
end

if ~iscell(filenames) && length(filenames) == 1 && filenames == 0 %if user canceled file operation, return
    cd(origDir);
    return;
end

if addFile
    if ~iscell(filenames)
        filenames = {filenames};f
    end
    info = get(guiObjects.openSelected,'UserData');
    filepath = {filepath};
    for i=2:length(filenames)
        filepath{i} = filepath{1};
    end
    filenames = cat(2,info.filenames,filenames);
    filepath = cat(2,info.filepath,filepath);
end

if iscell(filenames)%check if multiple files
    
    multiData = true; %set multiple datasets flag to true
    
    catData = cell(1,length(filenames)); %initialize cells
    catDataCell = {};
    catExper = cell(1,length(filenames));
    catVR = cell(1,length(filenames));
    indDataCells = cell(1,length(filenames));
    virmenFlag = zeros(1,length(filenames));
    dataTrials = zeros(1,length(filenames));
    pathDir = cd;
    for i=1:length(filenames)
        if iscell(filepath)
            cd(filepath{i});
        else
            cd(filepath);
        end
        load(filenames{i}); %load cell file
        matFileName = regexp(filenames{i},'_Cell','split'); %create string for other mat file
        matFileName = [matFileName{1} matFileName{2}];
        load(matFileName); %load mat file
        if exist('exper')
            virmenFlag(i) = true;
        end
        if exist('vr')
            catVR{i} = vr;
        end
        if ~isempty(dataCell)
            dataCell = parseDataArray(dataCell,data);
        end
        indDataCells{i} = dataCell; %#ok<*NODEF>
        dataTrials(i) = length(dataCell);
        catDataCell = cat(2,catDataCell,dataCell); %copy data into cells
        catData{i} = data;
        if virmenFlag(i)
            catExper{i} = exper;
        end
        cd(pathDir);
    end
    dataCell = catDataCell;
    exper = catExper;
    data = catData;
    if ~isempty(catVR)
        vr = catVR;
    end
    experCodes=cellfun(@(x) func2str(x.experimentCode),catExper,'UniformOutput',false);
    if ~all(cell2mat(cellfun(@(x) strcmp(experCodes{1},x),experCodes,'UniformOutput',false))) %check for different experiments
        questAns = questdlg('These files contain different experiments. Are you sure you want to continue?',...
            'Warning: Different Experiments','Yes','No','No');
        if strcmp(questAns,'No')
            cd(origDir);
            return;
        end
    end
    animals = cell2mat(cellfun(@(x) x{1}.info.mouse,indDataCells,'UniformOutput',false));
    if ~all(animals(1) == animals(:)) %if different animals
        anQuestAns = questdlg('These files are from different mice. Are you sure you want to continue?',...
            'Warning: Different Animals','Yes','No','No'); 
        if strcmp(anQuestAns,'No')
            cd(origDir);
            return;
        end
    end
    if ~all(virmenFlag(1) == virmenFlag(:)) %if mixed virmen files
        virAns = questdlg('These files are from both virmen and non-virmen experiments. Are you sure you want to continue?',...
            'Warning: Mixed ViRMEn','Yes','No','No'); 
        if strcmp(virAns,'No')
            cd(origDir);
            return;
        end
        virmenFlag = virmenFlag(1);
    end
else
    cd(filepath);
    multiData = false; %set multiple datasets flag to false
    
    if online
        if ~exist([guiObjects.userData.tempName,'.mat'],'file') %if live files no longer exist
            min_elapsed = 0;
            tstart = tic;
            esc_pressed = false;
            while 1
                if toc(tstart)>min_elapsed*60
                    fprintf('Cannot find MAT file: %d min elapsed.\n',min_elapsed)
                    min_elapsed = min_elapsed + 1;
                end
                
                % check whether esc key is pressed
                [keyIsDown, ~, keyCode, ~] = KbCheck;
                if keyIsDown
                    fprintf('Some key was pressed.\n')
                    if sum(keyCode)==1 % accept single key press only
                        esc_pressed = find(keyCode)==27;
                        if esc_pressed
                            fprintf('ESC key was pressed.\n')
                        end
                    end
                end
                
                % terminate if MAT file cannot be found for 10 min or ESC key was pressed
                if min_elapsed>60 || esc_pressed
                    startStopOnline_CALLBACK(src,evnt,guiObjects); %stop acquisition
                    cd(origDir);
                    fprintf('Stop Live Acq.\n')
                    return; % end Live Acq
                end
                
                if exist([guiObjects.userData.tempName,'.mat'],'file')
                    % if a new MAT file is found, resume Live Acq
                    fprintf('Found a new MAT file.\n');
                    pause(10); % wait for 10 sec
                    guiObjects = startStopOnline_CALLBACK(src,evnt,guiObjects); %stop acquisition
                    guiObjects = startStopOnline_CALLBACK(src,evnt,guiObjects); %restart acquisition
                    break
                end
            end
        end
        exper = copyExper(filepath,guiObjects.userData.tempName);
%         reshapeSize = copyReshapeSize(filepath,guiObjects.userData.tempName);
        if ~isfield(guiObjects,'data')
            currentStoredData = -1;
            data = [];
            startCell = 1;
            dataCell = [];
        else
            data = guiObjects.data;
            currentStoredData = numel(data);
            dataCell = guiObjects.dataCell;
            startCell = length(dataCell) + 1;
        end
        % emergency patch, change runDMTS!
        if 0
            exper.variables.inITI_ind = '8';
            exper.variables.reshapeSize = '8';
        end
        data = cat(2,data,copyData(filepath,guiObjects.userData.tempName,...
            str2double(exper.variables.reshapeSize),false,currentStoredData));
        if exist('exper') %#ok<*EXIST>
            virmenFlag = true;
        else
            virmenFlag = false;
        end
        % if exper == 0
        %     virmenFlag = false;
        % else
        %     virmenFlag = true;
        % end
        [dataCell] = cat(2,dataCell,catCells(fileToLoad,'data',startCell)); %concatenate cells into dataCell
        if isempty(dataCell)
            load(fileToLoad,'conds');
        else
            conds = dataCell{1}.info.conditions;
        end
    else
        load(filenames); %load file normally
        matFileName = regexp(filenames,'_Cell','split'); %create string for other mat file
        matFileName = [matFileName{1} matFileName{2}];
        load(matFileName); %load mat file
        if exist('exper') %#ok<*EXIST>
            virmenFlag = true;
        else
            virmenFlag = false;
        end
    end
    
    if ~isempty(dataCell)
        dataCell = parseDataArray(dataCell,data,exper);
    end
    dataTrials = length(dataCell); %set dataTrials to number of trials in single dataCell
end

%store current version of filenames
if ~addFile
    info.filepath = {filepath};
    if ~iscell(filenames)
        filenames = {filenames};
    end
    for i=2:length(filenames)
        info.filepath{i} = info.filepath{1};
    end
else
    info.filepath = filepath;
end
info.filenames = filenames;
set(guiObjects.openSelected,'UserData',info);

cd(origDir); %change back to original directory

%update figure name
if isempty(dataCell)
    anName = '';
    if virmenFlag 
        experName = func2str(exper.experimentCode);
    else
        experName = '';
    end
elseif multiData
    anName = '';
    anNames = unique(animals);
    for i=1:length(anNames)
        anName = [anName,guiObjects.userData.initials,sprintf('%03d',anNames(i)),' '];
    end
    if all(virmenFlag) && iscell(exper) %#ok<*EXIST>
        experName = func2str(exper{1}.experimentCode);
    else
        experName = '';
    end
else
    if dataCell{1}.info.mouse <inf
        guiObjects.userData.initials = 'KL';
    else
        guiObjects.userData.initials = 'XX';
    end
    anName = [guiObjects.userData.initials,sprintf('%03d',dataCell{1}.info.mouse)];
    if virmenFlag
        experName = func2str(exper.experimentCode);
    else
        experName = '';
    end
end


set(guiObjects.figHandle,'Name',['Behavioral Analysis Suite v1.0 -- Animal: ',...
    anName,' -- Maze: ',experName]);
guiObjects.anName = anName;
guiObjects.experName = experName;
guiObjects.dateName = datestr(now,'yymmdd');

%get guiData
winSize = str2double(get(guiObjects.winSize,'String'));
sessionTimeVector = rem(datenum(get(guiObjects.sessionTime,'String')),1);

%fix duration bug
for i=1:length(dataCell)
    tempVec = datevec(dataCell{i}.time.stop - dataCell{i}.time.start);
    dataCell{i}.time.duration = tempVec(4)*60 + tempVec(5) + tempVec(6)/60;
end

%process data
[procData] = processDataCell(data,dataCell);

%update table
condText_CALLBACK(src,evnt,dataCell,data,guiObjects,online);

%update sliding window plot
%calculate sliding window
if procData.sessionTime > winSize
    if multiData
        for i=1:length(catData)
            [procData.winData{i},guiObjects] = calcSlidingWindowCell(...
                indDataCells{i},catData{i},...
                dNumToMin(catData{i}(1,end)-catData{i}(1,1)),winSize,guiObjects);
        end
    else
        [procData.winData,guiObjects] = calcSlidingWindowCell(dataCell,data,...
            procData.sessionTime,winSize,guiObjects);
    end
    procData.winFlag = false;
else
    procData.winFlag = true;
end

%update raster plot
[guiObjects] = plotTrialRasterCell(dataCell,data,procData,guiObjects,dataTrials);

%for opto-stim trials, create a window title
if exist('vr','var')
    if isfield(vr,'stim') && ~isfield(guiObjects,'title_txt')
        title_txt = [];
        for si = 1:length(vr.stim)
            if vr.stim(si).prob > 0 && ~strcmp(vr.stim(si).label,'NO_STIM') && exist('vr.stim(si).sample')==1
                title_txt = [title_txt,sprintf('%s %dmW (%d,%d,%d,%d)\t',...
                    vr.stim(si).label,vr.stim(si).power,vr.stim(si).sample,vr.stim(si).delay,vr.stim(si).test,vr.stim(si).turn)];
            elseif vr.stim(si).prob > 0 && ~strcmp(vr.stim(si).label,'NO_STIM')
                title_txt = [title_txt,sprintf('%s %dmW GreyMaze\t',...
                    vr.stim(si).label,vr.stim(si).power)];
            end
        end
        title_txt = strrep(title_txt,'_',' ');
        guiObjects.title_txt = title_txt;
    end
end

%plot
if ~all(procData.winFlag)
    set(guiObjects.winText,'visible','off');
    if multiData
        [guiObjects] = plotWindowDataCellMulti(procData.winData,guiObjects);
    else
        [guiObjects] = plotWindowDataCell(procData.winData,guiObjects);
    end
    set(guiObjects.winDisp,'enable','on');
    set(guiObjects.legendCheck,'enable','on');
    if ~online
        set(guiObjects.panButton,'enable','on');
        set(guiObjects.zoomButton,'enable','on');
    else
        set(guiObjects.panButton,'enable','off');
        set(guiObjects.zoomButton,'enable','off');
    end
else
    set(guiObjects.winText,'visible','on');
    if isfield(guiObjects,'windowPlot') && ishandle(guiObjects.windowPlot)
        delete(guiObjects.windowPlot); %delete old plot
    end
    set(guiObjects.winDisp,'String',{'Correct','Trials'},'Value',[1 2]);
    set(guiObjects.winDisp,'enable','off');
    set(guiObjects.legendCheck,'enable','off');
    set(guiObjects.panButton,'enable','off');
    set(guiObjects.zoomButton,'enable','off');
end

%set condition
if online
    if isempty(dataCell)
        set(guiObjects.condDisp(2),'String',[]);
    else
        set(guiObjects.condDisp(2),'String',dataCell{end}.maze.condition);
        % set(guiObjects.condDisp(2),'String',conds{data(7,end)});
    end
end

%check for session end
if online && procData.sessionTimeVector >= sessionTimeVector
    set(guiObjects.sessionTime,'ForegroundColor',[1 0 0]);
    set(guiObjects.sessionText,'ForegroundColor',[1 0 0]);
else
    set(guiObjects.sessionTime,'ForegroundColor',[0 0 0]);
    set(guiObjects.sessionText,'ForegroundColor',[0 0 0]);
end

%save info to guiObjects
guiObjects.dataCell = dataCell;
guiObjects.data = data;
guiObjects.procData = procData;
guiObjects.exper = exper;
if exist('vr')
    guiObjects.vr = vr;
elseif isfield(guiObjects,'vr')
    guiObjects = rmfield(guiObjects,'vr');
end
guiObjects.multiData = multiData;
if multiData
    guiObjects.indDataCells = indDataCells;
    guiObjects.catData = catData;
end

%enable gui elements
if online
    set(guiObjects.openSelected,'enable','off','visible','on');
    set(guiObjects.openRecent,'enable','off','visible','on');
    set(guiObjects.add,'visible','off','enable','off');
    set(guiObjects.replace,'visible','off','enable','off');
    set(guiObjects.updateInt,'enable','on');
    set(guiObjects.sessionTime,'enable','on');
    set(guiObjects.lastX,'enable','on');
    set(guiObjects.datePopup,'enable','off');
    set(guiObjects.dateButtonRight,'enable','off');
    set(guiObjects.dateButtonLeft,'enable','off');
    set(guiObjects.animalPopup,'enable','off');
    set(guiObjects.animalButtonLeft,'enable','off');
    set(guiObjects.animalButtonRight,'enable','off');
    set(guiObjects.mouseToggle,'enable','off');
    set(guiObjects.condDisp(:),'visible','on');
else
    set(guiObjects.openSelected,'visible','off','enable','off');
    set(guiObjects.openRecent,'visible','off','enable','off');
    set(guiObjects.add,'visible','on','enable','on');
    set(guiObjects.replace,'visible','on','enable','on');
    set(guiObjects.updateInt,'enable','off');
    set(guiObjects.sessionTime,'enable','off');
    set(guiObjects.lastX,'enable','off');
    set(guiObjects.condDisp(:),'visible','off');
end
set(guiObjects.structureDisplay,'enable','on');
set(guiObjects.runModule,'enable','on');
set(guiObjects.moduleList,'enable','on');
set(guiObjects.modData,'enable','on');
set(guiObjects.export,'enable','on');
set(guiObjects.condText(:),'enable','on');
set(guiObjects.condCheck(:),'enable','on');
set(guiObjects.condRange(:),'enable','on');
set(guiObjects.suppressWarn,'enable','on');
set(guiObjects.clear,'enable','on');
set(guiObjects.winDisp,'Callback',{@windowCheck_CALLBACK,guiObjects,procData});
set(guiObjects.legendCheck,'Callback',{@windowCheck_CALLBACK,guiObjects,procData});

%initialize animal and date browser
if ~online && ~multiData
    initializeAnDateChange(filepath,filenames,guiObjects);
    set(guiObjects.datePopup,'enable','on');
    set(guiObjects.dateButtonRight,'enable','on');
    set(guiObjects.dateButtonLeft,'enable','on');
    set(guiObjects.animalPopup,'enable','on');
    set(guiObjects.animalButtonLeft,'enable','on');
    set(guiObjects.animalButtonRight,'enable','on');
    set(guiObjects.mouseToggle,'enable','on');
end

%update callbacks
set(guiObjects.tableList,'Callback',{@condText_CALLBACK,dataCell,data,guiObjects,online});
set(guiObjects.winSize,'Callback',{@winSize_CALLBACK,dataCell,data,guiObjects});
set(guiObjects.legendCheck,'Callback',{@windowCheck_CALLBACK,guiObjects,procData});
set(guiObjects.winDisp,'Callback',{@windowCheck_CALLBACK,guiObjects,procData});
set(guiObjects.structureDisplay,'Callback',{@strucTree_CALLBACK,dataCell});
set(guiObjects.condText(:),'Callback',{@condText_CALLBACK,dataCell,data,guiObjects,online});
set(guiObjects.condCheck(:),'Callback',{@condText_CALLBACK,dataCell,data,guiObjects,online});
set(guiObjects.condRange(:),'Callback',{@condText_CALLBACK,dataCell,data,guiObjects,online});
set(guiObjects.lastX,'Callback',{@condText_CALLBACK,dataCell,data,guiObjects,online});
set(guiObjects.animalButtonRight,'Callback',{@changeAnimalCell_CALLBACK,guiObjects,0,1});
set(guiObjects.animalButtonLeft,'Callback',{@changeAnimalCell_CALLBACK,guiObjects,0,0});
set(guiObjects.animalPopup,'Callback',{@changeAnimalCell_CALLBACK,guiObjects,1});
set(guiObjects.dateButtonRight,'Callback',{@changeDateCell_CALLBACK,guiObjects,0,1});
set(guiObjects.dateButtonLeft,'Callback',{@changeDateCell_CALLBACK,guiObjects,0,0});
set(guiObjects.datePopup,'Callback',{@changeDateCell_CALLBACK,guiObjects,1});
set(guiObjects.mouseToggle,'Callback',{@mouseToggle_CALLBACK,guiObjects});
set(guiObjects.runModule,'Callback',{@runModule_CALLBACK,guiObjects});
set(guiObjects.add,'Callback',{@openCellFiles_CALLBACK,guiObjects,false,'',false,true});
set(guiObjects.export,'Callback',{@exportData_CALLBACK,guiObjects});
set(guiObjects.clear,'Callback',{@resetCondFields_CALLBACK,guiObjects,dataCell,data,online});
if online
    set(guiObjects.sessionTime,'Callback',{@openCellFiles_CALLBACK,guiObjects,true,fileToLoad,true});
end
%save guiObjects
set(guiObjects.figHandle,'UserData',guiObjects);

if isfield(guiObjects,'batch_flag')
    if guiObjects.batch_flag
        callbackCell = get(guiObjects.print,'Callback');
        callbackCell{1}(guiObjects.openSelected,[],callbackCell{2})
        close all
    end
end
    
