function [winData,guiObjects] = calcSlidingWindowCell(dataCell,data,sessionTime,winSize,guiObjects)
%calcSlidingWindow.m Function which uses dataCell to calculate information
%over a sliding window
%
%incSize = size of increment (in fraction of window)
tstart = tic;
incSize = .005;

if sessionTime<winSize
    return;
end

winSizeInd = ceil(size(data,2)*winSize/sessionTime); %get size of window in indices
incSizeInd = ceil(winSizeInd*incSize);

winData.startTimes = data(1,1:incSizeInd:size(data,2)+1-winSizeInd);
stopTimes = data(1,winSizeInd:incSizeInd:size(data,2));

if length(winData.startTimes) ~= length(stopTimes)
    winSizeInd = floor(size(data,2)*winSize/sessionTime); %get size of window in indices
    incSizeInd = round(winSizeInd*incSize);
    winData.startTimes = data(1,1:incSizeInd:size(data,2)+1-winSizeInd);
    stopTimes = data(1,winSizeInd:incSizeInd:size(data,2));
end

flagStrs = guiObjects.userData.flags; %get flags 
winVars{1} = {'winData.nTrials',0,'true'};
winVars{2} = {'winData.nRewards',0,'result.correct==1'};
winVars = cat(2,winVars,guiObjects.userData.winVars);

percVars{1} = {0,'winData.percCorr','winData.nRewards','winData.nTrials'};
percVars = cat(2,percVars,guiObjects.userData.percVars);

flags = zeros(1,length(flagStrs));
for i=1:length(flagStrs) %for each flag
    eval(['flags(i) = ',flagStrs{i},';']);
end

%update listbox
listStrs = {'Correct','Trials Per Minute'};
for i=2:length(percVars)
    if percVars{i}{1} == 0 || flags(percVars{i}{1})
        listStrs = [listStrs,guiObjects.userData.percVarNames{i-1}];
    end
end
set(guiObjects.winDisp,'String',listStrs);

%initialize each array
for i=1:length(winVars)
    if winVars{i}{2} == 0 || flags(winVars{i}{2})
        eval([winVars{i}{1},' = zeros(size(winData.startTimes));']);
    end
end
a(1) = toc(tstart);
for i=1:length(dataCell)
    trialStart = dataCell{i}.time.start;
    trialEnd = dataCell{i}.time.stop; %#ok<*NASGU>
    
    for j=1:length(winVars)
        if winVars{j}{2} == 0 || flags(winVars{j}{2}) %only if flag is satisfied
            booleans = '';
            for k=3:length(winVars{j})
                if strcmpi(winVars{j}{k},'true')
                    if k == length(winVars{j})
                        booleans = [booleans,winVars{j}{k}];
                    else
                        booleans = [booleans,winVars{j}{k},' && ']; %#ok<*AGROW>
                    end
                else
                    if k == length(winVars{j})
                        booleans = [booleans,'dataCell{i}.',winVars{j}{k}];
                    else
                        booleans = [booleans,'dataCell{i}.',winVars{j}{k},' && '];
                    end
                end
            end
            conditional = ['if ',booleans,'; '...
                winVars{j}{1},'(trialStart >= winData.startTimes & trialEnd <= stopTimes) =',...
                winVars{j}{1},'(trialStart >= winData.startTimes & trialEnd <= stopTimes) + 1;',...
                'end'];
            try
                eval(conditional);
            catch
            end
        end
    end
    
end
a(2) = toc(tstart);

%calculate percentages
winData.legNames{1} = 'Correct';
winData.legNames{2} = 'Trials Per Minute';
for i=1:length(percVars)
    if percVars{i}{1} == 0 || flags(percVars{i}{1})
        eval([percVars{i}{2},' = 100*',percVars{i}{3},'./',percVars{i}{4},';']);
        winData.names{i} = percVars{i}{2};
        if i~=1
            winData.legNames{i+1} = guiObjects.userData.percVarNames{i-1};
        end
    end
end

%calculate trials per minute
winData.trialsPerMinute = winData.nTrials./winSize;
a(3) = toc(tstart);

%get totTime
winData.totTime = length(1:incSizeInd:size(data,2));
