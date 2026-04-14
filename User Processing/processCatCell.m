function [catData] = processCatCell(dataCell)
% processCatCell.m
% Process category-task trial data saved by createSaveStructCategory.
%
% Assumes dataCell is a cell array of trial structs and that each trial
% contains fields such as:
%   maze.category
%   maze.stimAngle
%   result.correct
%   result.leftTurn
%   result.rewardSize
%   time.duration
%
% Optional fields that may exist:
%   maze.rewLeft
%   maze.crutchTrial
%   maze.condition
%
% The function returns summary statistics split by category and, when
% available, by crutch / non-crutch trials.

catData = struct();

if isempty(dataCell)
    catData = initializeEmptyCatData(catData);
    return;
end

% Ensure ITI fields exist
if ~isfield(dataCell{1}.info,'itiCorrect')
    dataCell{1}.info.itiCorrect = 2;
    dataCell{1}.info.itiMiss = 4;
end

% --------------------------
% Basic overall summaries
% --------------------------
catData.nTrials = numel(dataCell);
catData.nCorrect = sum(findTrials(dataCell,'result.correct==1'));
catData.fracCorrect = catData.nCorrect / catData.nTrials;
catData.percCorrect = 100 * catData.fracCorrect;

catData.nLeftTurns = sum(findTrials(dataCell,'result.leftTurn==1'));
catData.percLeftTurns = 100 * catData.nLeftTurns / catData.nTrials;

catData.nCat0Trials = sum(findTrials(dataCell,'maze.category==0'));
catData.percCat0Trials = 100 * catData.nCat0Trials / catData.nTrials;

catData.meanTrialDur = mean(getCellVals(dataCell,'time.duration'));
catData.stdTrialDur = std(getCellVals(dataCell,'time.duration'));

if isfield(dataCell{1}.result,'rewardSize')
    catData.nRewardsRec = sum(getCellVals(dataCell,'result.rewardSize'));
else
    catData.nRewardsRec = NaN;
end

catData.sessionTime = ...
    (sum(getCellVals(dataCell,'time.duration')) + ...
    dataCell{1}.info.itiCorrect * catData.nCorrect + ...
    dataCell{1}.info.itiMiss * (catData.nTrials - catData.nCorrect)) / 60;

catData.trialsPerMin = catData.nTrials / catData.sessionTime;
catData.rewPerMin = catData.nCorrect / catData.sessionTime;

% --------------------------
% Split by stimulus category
% --------------------------
cat0Cell = getTrials(dataCell,'maze.category==0');
cat1Cell = getTrials(dataCell,'maze.category==1');

catData.cat0 = summarizeSubset(cat0Cell, dataCell{1}.info);
catData.cat1 = summarizeSubset(cat1Cell, dataCell{1}.info);

% --------------------------
% Stimulus angle summaries
% --------------------------
if isfield(dataCell{1}.maze,'stimAngle')
    allAngles = getCellVals(dataCell,'maze.stimAngle');
    uniqueAngles = unique(allAngles(~isnan(allAngles)));

    catData.uniqueAngles = uniqueAngles;
    catData.nTrialsByAngle = nan(size(uniqueAngles));
    catData.nCorrectByAngle = nan(size(uniqueAngles));
    catData.percCorrectByAngle = nan(size(uniqueAngles));
    catData.percLeftByAngle = nan(size(uniqueAngles));

    for i = 1:numel(uniqueAngles)
        ang = uniqueAngles(i);
        angCell = getTrials(dataCell, ['maze.stimAngle==', num2str(ang)]);
        catData.nTrialsByAngle(i) = numel(angCell);
        catData.nCorrectByAngle(i) = sum(findTrials(angCell,'result.correct==1'));
        catData.percCorrectByAngle(i) = 100 * catData.nCorrectByAngle(i) / catData.nTrialsByAngle(i);
        catData.percLeftByAngle(i) = 100 * sum(findTrials(angCell,'result.leftTurn==1')) / catData.nTrialsByAngle(i);
    end
else
    catData.uniqueAngles = [];
    catData.nTrialsByAngle = [];
    catData.nCorrectByAngle = [];
    catData.percCorrectByAngle = [];
    catData.percLeftByAngle = [];
end

% --------------------------
% Reward-side summaries
% --------------------------
if isfield(dataCell{1}.maze,'rewLeft')
    rewLeftCell = getTrials(dataCell,'maze.rewLeft==1');
    rewRightCell = getTrials(dataCell,'maze.rewLeft==0');

    catData.rewLeft = summarizeSubset(rewLeftCell, dataCell{1}.info);
    catData.rewRight = summarizeSubset(rewRightCell, dataCell{1}.info);
end

% --------------------------
% Crutch summaries
% --------------------------
if isfield(dataCell{1}.maze,'crutchTrial')
    crutchCell = getTrials(dataCell,'maze.crutchTrial==1');
    noCrutchCell = getTrials(dataCell,'maze.crutchTrial==0');

    catData.crutch = summarizeSubset(crutchCell, dataCell{1}.info);
    catData.noCrutch = summarizeSubset(noCrutchCell, dataCell{1}.info);
else
    crutchCell = dataCell(:);
    noCrutchCell = [];

    catData.crutch = summarizeSubset(crutchCell, dataCell{1}.info);
    catData.noCrutch = summarizeSubset(noCrutchCell, dataCell{1}.info);
end

% --------------------------
% Optional confusion-style counts
% --------------------------
% For this task, the correct mapping in runtime is:
%   category==0 -> correct left turn
%   category==1 -> correct right turn
%
% This follows from the reward logic in TmazeMoveTowerVisGuide.
catData.nCat0_LeftChoice  = sum(findTrials(dataCell,'maze.category==0; result.leftTurn==1'));
catData.nCat0_RightChoice = sum(findTrials(dataCell,'maze.category==0; result.leftTurn==0'));
catData.nCat1_LeftChoice  = sum(findTrials(dataCell,'maze.category==1; result.leftTurn==1'));
catData.nCat1_RightChoice = sum(findTrials(dataCell,'maze.category==1; result.leftTurn==0'));

end


function out = summarizeSubset(subCell, infoStruct)

if isempty(subCell)
    out.nTrials = NaN;
    out.nCorrect = NaN;
    out.fracCorrect = NaN;
    out.percCorrect = NaN;
    out.percLeftTurns = NaN;
    out.meanTrialDur = NaN;
    out.stdTrialDur = NaN;
    out.sessionTime = NaN;
    out.trialsPerMin = NaN;
    out.rewPerMin = NaN;
    out.nRewardsRec = NaN;
    return;
end

out.nTrials = numel(subCell);
out.nCorrect = sum(findTrials(subCell,'result.correct==1'));
out.fracCorrect = out.nCorrect / out.nTrials;
out.percCorrect = 100 * out.fracCorrect;
out.percLeftTurns = 100 * sum(findTrials(subCell,'result.leftTurn==1')) / out.nTrials;
out.meanTrialDur = mean(getCellVals(subCell,'time.duration'));
out.stdTrialDur = std(getCellVals(subCell,'time.duration'));

if isfield(subCell{1}.result,'rewardSize')
    out.nRewardsRec = sum(getCellVals(subCell,'result.rewardSize'));
else
    out.nRewardsRec = NaN;
end

out.sessionTime = ...
    (sum(getCellVals(subCell,'time.duration')) + ...
    infoStruct.itiCorrect * out.nCorrect + ...
    infoStruct.itiMiss * (out.nTrials - out.nCorrect)) / 60;

out.trialsPerMin = out.nTrials / out.sessionTime;
out.rewPerMin = out.nCorrect / out.sessionTime;

end


function catData = initializeEmptyCatData(catData)

catData.nTrials = 0;
catData.nCorrect = 0;
catData.fracCorrect = NaN;
catData.percCorrect = NaN;
catData.nLeftTurns = 0;
catData.percLeftTurns = NaN;
catData.meanTrialDur = NaN;
catData.stdTrialDur = NaN;
catData.nRewardsRec = NaN;
catData.sessionTime = NaN;
catData.trialsPerMin = NaN;
catData.rewPerMin = NaN;

catData.cat0 = struct();
catData.cat1 = struct();
catData.uniqueAngles = [];
catData.nTrialsByAngle = [];
catData.nCorrectByAngle = [];
catData.percCorrectByAngle = [];
catData.percLeftByAngle = [];

end