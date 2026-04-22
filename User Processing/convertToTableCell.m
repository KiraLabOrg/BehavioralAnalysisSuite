function [table] = convertToTableCell(procData)
%convertToTableCell.m This function converts data processed by
%processDataCell.m and converts it to a table format. Each section
%corresponds to a section of the table whose visibility can be modified by
%the table view listbox in the gui. The special section provides a space
%for any special parameters as designated by the current maze.
%
%Any variables created in processDataCell.m must be included here to be
%displayed properly. This is divided into four sections: General,
%Conditions, Timing, and Special. The visibility of these portions of the
%table can be easily modified using the listbox in the GUI. This prevents
%having too many variables in the table at any given time. The table
%structure contains four fields corresponding to each section
%
%To include variables in the table, use the format below. There are two
%fields that must be filled for each variable: data and names. Each
%category (general, etc.) is a nonscalar structure array with as many
%fields as there are variables. Thus, the first portion of the assignment,
%which grows the structure is essential. Assign variables calculated in
%processDataCell.m and stored in the procData array using this format.
%The names field is a cell array of strings corresponding to the row names
%of each variable in the table. Order matters and must match the order in
%which variables are defined in the data section.
%
%Below is an example of the definition of two variables: procData.nTrials
%and procData.nRewards to the table.
%
%table.general.data(size(table.general.data,1)+1,1) = procData.nTrials;
%table.general.data(size(table.general.data,1)+1,1) = procData.nRewards;
%table.general.names = {'nTrials','nRewards'};
%
%In the special section, the user will likely want to define specific
%conditions under which to display fields. For example, in a specific task,
%there might be a variable one wishes to display. If statements using
%'isfield' are useful for this. See the below example:
%
% if isfield(procData,'greyFac')
%     table.special.data(size(table.special.data,1)+1,1) = procData.greyFac;
%     table.special.data(size(table.special.data,1)+1,1) = procData.netCount;
%     table.special.names = {'greyFac','netCount'};
% end
%
%ASM 9/12


%session time - DO NOT MODIFY
table.sessionTime.data = datestr(procData.sessionTimeVector,'HH:MM:SS');
table.sessionTime.names = {'Elapsed Time'};

%Initialize - DO NOT MODIFY
table.general.data = [];
table.general.names = {};
table.conditions.data = [];
table.conditions.names = {};
table.timing.data = []; 
table.timing.names = {};
table.special.data = [];
table.special.names = {};

%MODIFY THE SECTIONS BELOW
%general
table.general.data(size(table.general.data,1)+1,1) = procData.nRewards;
table.general.data(size(table.general.data,1)+1,1) = procData.nTrials;
table.general.data(size(table.general.data,1)+1,1) = procData.percCorr;
table.general.data(size(table.general.data,1)+1,1) = procData.percLeft;
table.general.names = {'nRewards','nTrials','Percent Correct','Percent Left Turns'};

%conditions
numConds = length(procData.nTrialsConds);
[condStrings] = generateCondStrings(numConds); %This function generates as many strings as necessary in the format 'Condition 1 Trials', 'Condition 2 Trials', etc.

for i=1:numConds
    table.conditions.data(size(table.conditions.data,1)+1,1) = procData.percCorrConds(i);
    table.conditions.data(size(table.conditions.data,1)+1,1) = procData.nTrialsConds(i);
    table.conditions.data(size(table.conditions.data,1)+1,1) = procData.nRewConds(i);
    table.conditions.names = [table.conditions.names...
        condStrings.percCorr{i},condStrings.trials{i},condStrings.rewards{i}];
end

%timing
table.timing.data(size(table.timing.data,1)+1,1) = procData.trialsPerMin;
table.timing.data(size(table.timing.data,1)+1,1) = procData.rewPerMin;
table.timing.data(size(table.timing.data,1)+1,1) = procData.meanTrialDur;
table.timing.data(size(table.timing.data,1)+1,1) = procData.stdTrialDur;
table.timing.names = {'Trials Per Minute','Rewards Per Minute','Mean Trial Duration',...
    'STD of Trial Duration'};
    
%special
if isfield(procData,'catData')
    table.general.data(size(table.general.data,1)+1,1) = procData.catData.percCat0Trials;
    table.special.data(end+1,1) = procData.catData.crutch.nCorrect;
    table.special.data(end+1,1) = procData.catData.crutch.nTrials;
    table.special.data(end+1,1) = procData.catData.crutch.percCorrect;

    table.special.data(end+1,1) = procData.catData.noCrutch.nCorrect;
    table.special.data(end+1,1) = procData.catData.noCrutch.nTrials;
    table.special.data(end+1,1) = procData.catData.noCrutch.percCorrect;

    table.special.data(end+1,1) = procData.streak;

    table.special.names = [table.special.names, ...
        {'Percent Cat0', ...
         'nRewards Crutch', 'nTrials Crutch', 'Percent Correct Crutch', ...
         'nRewards NoCrut', 'nTrials NoCrut', 'Percent Correct NoCrut', ...
         'Streak'}];
end

if isfield(procData,'pairedData') %paired
    table.special.data(size(table.special.data,1)+1,1) = procData.pairedData.percCorrTower;
    table.special.data(size(table.special.data,1)+1,1) = procData.pairedData.nTrialsTower;
    table.special.data(size(table.special.data,1)+1,1) = procData.pairedData.nRewardsTower;
    table.special.data(size(table.special.data,1)+1,1) = procData.pairedData.percCorrNoTower;
    table.special.data(size(table.special.data,1)+1,1) = procData.pairedData.nTrialsNoTower;
    table.special.data(size(table.special.data,1)+1,1) = procData.pairedData.nRewardsNoTower;
    table.special.data(size(table.special.data,1)+1,1) = procData.pairedData.percLeftTower;
    table.special.data(size(table.special.data,1)+1,1) = procData.pairedData.fracLeftTower;
    table.special.data(size(table.special.data,1)+1,1) = procData.pairedData.percWhiteTower;
    table.special.data(size(table.special.data,1)+1,1) = procData.pairedData.fracWhiteTower;
    table.special.data(size(table.special.data,1)+1,1) = procData.pairedData.percLeftNoTower;
    table.special.data(size(table.special.data,1)+1,1) = procData.pairedData.fracLeftNoTower;
    table.special.data(size(table.special.data,1)+1,1) = procData.pairedData.percWhiteNoTower;
    table.special.data(size(table.special.data,1)+1,1) = procData.pairedData.fracWhiteNoTower;
    table.special.names = {'Percent Correct Single Tower','nTrials Single Tower','nRewards Single Tower',...
        'Percent Correct Two Towers','nTrials Two Towers','nRewards Two Towers',...
        'Percent Left Turns Single Tower','Percent Left Trials Single Tower','Percent White Turns Single Tower',...
        'Percent White Trials Single Tower','Percent Left Turns Two Towers','Percent Left Trials Two Towers',...
        'Percent White Turns Two Towers','Percent White Trials Two Towers'};
    
    table.timing.data(size(table.timing.data,1)+1,1) = procData.pairedData.trialsPerMinTower;
    table.timing.data(size(table.timing.data,1)+1,1) = procData.pairedData.rewPerMinTower;
    table.timing.data(size(table.timing.data,1)+1,1) = procData.pairedData.trialsPerMinNoTower;
    table.timing.data(size(table.timing.data,1)+1,1) = procData.pairedData.rewPerMinNoTower;
    table.timing.data(size(table.timing.data,1)+1,1) = procData.pairedData.meanDurTower;
    table.timing.data(size(table.timing.data,1)+1,1) = procData.pairedData.stdDurTower;
    table.timing.data(size(table.timing.data,1)+1,1) = procData.pairedData.meanDurNoTower;
    table.timing.data(size(table.timing.data,1)+1,1) = procData.pairedData.stdDurNoTower;
    table.timing.names = [table.timing.names, {'Trials Per Minute Single Tower','Rewards Per Minute Single Tower',...
        'Mean Trial Duration Single Tower','STD of Trial Duration Single Tower','Trials Per Minute Two Towers',...
        'Rewards Per Minute Two Towers','Mean Trial Duration Two Towers','STD of Trial Duration Two Towers'}];
    
elseif isfield(procData,'pairedDelayData') %paired delay
    table.special.data(size(table.special.data,1)+1,1) = procData.pairedDelayData.percCorrNoDelay;
    table.special.data(size(table.special.data,1)+1,1) = procData.pairedDelayData.nTrialsNoDelay;
    table.special.data(size(table.special.data,1)+1,1) = procData.pairedDelayData.nRewardsNoDelay;
    table.special.data(size(table.special.data,1)+1,1) = procData.pairedDelayData.percCorrDelay;
    table.special.data(size(table.special.data,1)+1,1) = procData.pairedDelayData.nTrialsDelay;
    table.special.data(size(table.special.data,1)+1,1) = procData.pairedDelayData.nRewardsDelay;
    table.special.data(size(table.special.data,1)+1,1) = procData.pairedDelayData.percLeftNoDelay;
    table.special.data(size(table.special.data,1)+1,1) = procData.pairedDelayData.fracLeftNoDelay;
    table.special.data(size(table.special.data,1)+1,1) = procData.pairedDelayData.percWhiteNoDelay;
    table.special.data(size(table.special.data,1)+1,1) = procData.pairedDelayData.fracWhiteNoDelay;
    table.special.data(size(table.special.data,1)+1,1) = procData.pairedDelayData.percLeftDelay;
    table.special.data(size(table.special.data,1)+1,1) = procData.pairedDelayData.fracLeftDelay;
    table.special.data(size(table.special.data,1)+1,1) = procData.pairedDelayData.percWhiteDelay;
    table.special.data(size(table.special.data,1)+1,1) = procData.pairedDelayData.fracWhiteDelay;
    table.special.names = {'Percent Correct No Delay','nTrials No Delay','nRewards No Delayy',...
        'Percent Correct Delay','nTrials Delay','nRewards Delay',...
        'Percent Left Turns No Delay','Percent Left Trials No Delay','Percent White Turns No Delay',...
        'Percent White Trials No Delay','Percent Left Turns Delay','Percent Left Trials Delay',...
        'Percent White Turns Delay','Percent White Trials Delay'};
    
    table.timing.data(size(table.timing.data,1)+1,1) = procData.pairedDelayData.trialsPerMinNoDelay;
    table.timing.data(size(table.timing.data,1)+1,1) = procData.pairedDelayData.rewPerMinNoDelay;
    table.timing.data(size(table.timing.data,1)+1,1) = procData.pairedDelayData.trialsPerMinDelay;
    table.timing.data(size(table.timing.data,1)+1,1) = procData.pairedDelayData.rewPerMinDelay;
    table.timing.data(size(table.timing.data,1)+1,1) = procData.pairedDelayData.meanDurNoDelay;
    table.timing.data(size(table.timing.data,1)+1,1) = procData.pairedDelayData.stdDurNoDelay;
    table.timing.data(size(table.timing.data,1)+1,1) = procData.pairedDelayData.meanDurDelay;
    table.timing.data(size(table.timing.data,1)+1,1) = procData.pairedDelayData.stdDurDelay;
    table.timing.names = [table.timing.names, {'Trials Per Minute No Delay','Rewards Per Minute No Delay',...
        'Mean Trial Duration No Delay','STD of Trial Duration No Delay','Trials Per Minute Delay',...
        'Rewards Per Minute Delay','Mean Trial Duration Delay','STD of Trial Duration Delay'}];
end

if isfield(procData,'greyFac')
    table.special.data(size(table.special.data,1)+1,1) = procData.greyFac;
    % table.special.data(size(table.special.data,1)+1,1) = procData.netCount;
    % table.special.data(size(table.special.data,1)+1,1) = procData.stimOn;
    table.special.names = {'greyFac'};
end

    % added by SK 04/23/15
if isfield(procData,'twoFac')
    table.special.data(size(table.special.data,1)+1,1) = procData.twoFac;
    % table.special.names = {'twoFac'};
    table.special.names = [table.special.names, {'twoFac'}];
end
    
    % Added by VS 02/15/17
if isfield(procData,'probCrutch')
    table.special.data(size(table.special.data,1)+1,1) = procData.probCrutch;
    table.special.names = [table.special.names,{'probMask'}];
end

    %Added by VS 03/02/17
if isfield(procData,'stimInfo')
    table.special.data(size(table.special.data,1)+1,1) = procData.stimOn;
    table.special.data(size(table.special.data,1)+1,1) = procData.nRewardsStimOn;
    table.special.data(size(table.special.data,1)+1,1) = procData.nTrialsStimOn;
    table.special.data(size(table.special.data,1)+1,1) = procData.percCorrStimOn;
    table.special.data(size(table.special.data,1)+1,1) = procData.nRewardsStimOff;
    table.special.data(size(table.special.data,1)+1,1) = procData.nTrialsStimOff;
    table.special.data(size(table.special.data,1)+1,1) = procData.percCorrStimOff;
    table.special.names = [table.special.names,{'StimPower','nRewardsStimOn','nTrialsStimOn'},...
        'percCorrStimOn','nRewardsStimOff','nTrialsStimOff','percCorrStimOff'];
    
end

if isfield(procData,'delayLength')
    table.special.data(size(table.special.data,1)+1,1) = procData.delayLength;
    table.special.names = {'Delay Length'};
end

if isfield(procData,'mazeLength')
    table.special.data(size(table.special.data,1)+1,1) = procData.mazeLength;
    table.special.names = {'Maze Length'};
end

end