function [procData] = processDataCell(data,dataCell,subset)
%processDataCell.m Function to process data and output results
%
%This function takes in data (an array saved on every iteration of a given
%software) and dataCell (a cell array of length nTrials in which each cell
%is a structure containing all relevant data). In this section, the user
%can input any data which should be processed. Note that only variables
%saved in the procData structure will be saved. Anything else only exists within the
%function.
%
%Importantly, for processing to apply to a subset of trials, the dataCell
%must be used either exclusively or to parse the data array. Any operations
%performed on the whole of data will not take into account any trial
%filtering performed in the GUI, resulting in awry calculations. 
%
%If you need the session time, it is stored in procData.sessionTime as the
%time of the session in minutes
%
%ASM 9/12


%DO NOT MODIFY 
if nargin < 3; subset = false; end
if iscell(data); multiData = true; else multiData = false; end

%calculate nTrials and nRewards
procData.nTrials = size(dataCell,2);
procData.nRewards = sum(findTrials(dataCell,'result.correct==1'));

%calculate streak
if ~isempty(dataCell)
    if dataCell{end}.result.correct
        results = getCellVals(dataCell,'result.correct');
        procData.streak = length(results) - find(results==0,1,'last');
        if isempty(procData.streak)
            procData.streak = 1;
        end
    else
        results = getCellVals(dataCell,'result.correct');
        procData.streak = -1*(length(results) - find(results==1,1,'last'));
        if isempty(procData.streak)
            procData.streak = -1;
        end
    end
else
    procData.streak = 0;
end

%calculate session time
if ~isempty(dataCell)
    if ~isfield(dataCell{1}.info,'itiCorrect') %this is only present because I did not originally include itiMiss and itiCorrect in my structures. Should be irrelevant otherwise
        dataCell{1}.info.itiCorrect = 2;
        dataCell{1}.info.itiMiss = 4;
    end
    procData.sessionTime = sum(getCellVals(dataCell,'time.duration'))+...
        (dataCell{1}.info.itiCorrect*procData.nRewards +...
        dataCell{1}.info.itiMiss*(procData.nTrials-procData.nRewards))/60;
else
    procData.sessionTime = NaN;
end
if subset || multiData
    mins = floor(procData.sessionTime);
    secs = round(mod(procData.sessionTime,mins)*60);
    procData.sessionTimeVector = rem(datenum([sprintf('%02d',mins),':',...
        sprintf('%02d',secs)],'MM:SS'),1);
else
    procData.sessionTimeVector = data(1,end) - data(1,1);
end

%MODIFY THE BELOW AREA
%get number of rewards received and streak
procData.nRewardsRec = sum(getCellVals(dataCell,'result.rewardSize'));
% if ~isempty(dataCell)
%     procData.streak = dataCell{end}.result.streak;
% else
%     procData.streak = 0;
% end

%calculate number of trials and rewards for each condition
if ~isempty(dataCell)
    conditions = 1:length(dataCell{1}.info.conditions);
    for i=1:length(conditions)
        procData.nTrialsConds(i) = sum(findTrials(dataCell,['maze.condition == ',num2str(conditions(i))]));
        procData.nRewConds(i) = sum(findTrials(dataCell,['maze.condition == ',num2str(conditions(i)),...
            ';result.correct==1']));
    end
else
    procData.nTrialsConds = [];
    procData.nRewConds = [];
end

%calculate percent corrects
procData.percCorr = 100*procData.nRewards/procData.nTrials;
procData.percCorrConds = 100*(procData.nRewConds./procData.nTrialsConds);
procData.fracCorr = procData.nRewards/procData.nTrials;

%calculate percent/fraction left/white
procData.percLeft = 100*sum(findTrials(dataCell,'result.leftTurn==1'))/procData.nTrials;
% procData.percWhite = 100*sum(findTrials(dataCell,'result.whiteTurn==1'))/procData.nTrials;
procData.fracLeft = 100*sum(findTrials(dataCell,'maze.leftTrial==1'))/procData.nTrials;
procData.fracCat1 = 100*sum(findTrials(dataCell,'maze.condition==1'))/procData.nTrials;

%calculate mean+-std trial duration
procData.meanTrialDur = mean(getCellVals(dataCell,'time.duration'));
procData.stdTrialDur = std(getCellVals(dataCell,'time.duration'));

%calculate trialsPerMin and rewardsPerMin
procData.trialsPerMin = procData.nTrials/procData.sessionTime;
procData.rewPerMin = procData.nRewards/procData.sessionTime;

%process category
if ~isempty(dataCell) && isfield(dataCell{1}.maze,'category')
    procData.catData = processCatCell(dataCell);
end

%process paired 
if ~isempty(dataCell) && isfield(dataCell{1}.maze,'twoTowers')
    procData.pairedData = processPairedCell(dataCell);
end

%process paired delay
if ~isempty(dataCell) && isfield(dataCell{1}.maze,'delay')
    procData.pairedDelayData = processPairedDelayCell(dataCell);
end

%process greyFac
if ~isempty(dataCell) && isfield(dataCell{1}.maze,'greyFac') && ~isfield(dataCell{1}.maze,'delayLength')
    if ~multiData && size(data,1) >= 10
        procData.greyFac = data(10,end);
        procData.greyFacAll = data(10,:);
        if isfield(dataCell{1}.result,'netCount')
            procData.netCount = dataCell{end}.result.netCount;
        else
            procData.netCount = NaN;
        end
    end
end

% process twoFac
if ~isempty(dataCell) && isfield(dataCell{1}.maze,'twoFac') && ~isfield(dataCell{1}.maze,'delayLength')
    if ~multiData && size(data,1) >= 10
        procData.twoFac = data(10,end);
        procData.twoFacAll = data(10,:);
    end
end

% process probCrutch Added by VS 02/15/17
if ~isempty(dataCell) && isfield(dataCell{1}.maze,'probCrutch') 
    if ~multiData && size(data,1) >= 10
        procData.probCrutch = data(10,end);
        procData.probCrutchAll = data(10,:);
    end
end

% Add Stim/ No Stim VS 03/02/17
if ~isempty(dataCell) && isfield(dataCell{1},'stim') 
    if ~multiData && size(data,1) >= 10
        procData.stimOn = dataCell{end}.stim.power;
        procData.stimInfo = dataCell{end}.stim;
        procData.nTrialsStimOn = sum(findTrials(dataCell,'stim.power>0'));
        procData.nTrialsStimOff = sum(findTrials(dataCell,'stim.power==0'));
        procData.nRewardsStimOn = sum(findTrials(dataCell,'result.correct==1; stim.power>0'));
        procData.nRewardsStimOff = sum(findTrials(dataCell,'result.correct==1; stim.power==0'));
        procData.percCorrStimOn = 100*procData.nRewardsStimOn./procData.nTrialsStimOn;
        procData.percCorrStimOff = 100*procData.nRewardsStimOff./procData.nTrialsStimOff;
    end
end

% process delay
if ~isempty(dataCell) && isfield(dataCell{1}.maze,'delayLength')
    if ~multiData && size(data,1) >= 10
        procData.delayLength = data(10,end);
        procData.delayLengthAll = data(10,:);
    end
end

% process mazeLength
if ~isempty(dataCell) && isfield(dataCell{1}.maze,'mazeLength')
    if ~multiData && size(data,1) >= 10
        procData.mazeLength = data(10,end);
        procData.mazeLengthAll = data(10,:);
    end
end

