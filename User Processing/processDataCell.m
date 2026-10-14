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
        if isfield(dataCell{1}.maze,'category')
            twoFac_ind = 11;
        else
            twoFac_ind = 10;
        end
        procData.twoFac = data(twoFac_ind,end);
        procData.twoFacAll = data(twoFac_ind,:);
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

% Parse giveRewardKL.m to find uL per reward for this mouse.
% First checks all explicit ismember(vr.mouseNum,[...]) blocks.
% If the mouse is in the else/default branch, falls back to the consensus
% else-block value across all standard rigs (rigs 1-3 all default to 7 uL).
if ~isempty(dataCell)
    mouseNum_rew = dataCell{1}.info.mouse;
    procData.ulPerRew = NaN;
    rewardFile = which('giveRewardKL');
    if ~isempty(rewardFile)
        fid = fopen(rewardFile,'r');
        if fid > 0
            rewLines = {};
            tline = fgetl(fid);
            while ischar(tline)
                rewLines{end+1} = tline; %#ok<AGROW>
                tline = fgetl(fid);
            end
            fclose(fid);
            elseUL      = [];   % default uL values from else blocks (fallback)
            inElse      = false;
            for li = 1:length(rewLines)
                ln = rewLines{li};
                % --- explicit ismember match ---
                if ~isempty(regexp(ln,'ismember.*mouseNum','once'))
                    inElse = false;
                    miceToken = regexp(ln,'\[([^\]]*)\]','tokens','once');
                    if ~isempty(miceToken) && ~isempty(strtrim(miceToken{1}))
                        miceList = str2num(['[' miceToken{1} ']']); %#ok<ST2NM>
                        if ismember(mouseNum_rew, miceList)
                            for li2 = li+1:min(li+4,length(rewLines))
                                % Stop if we've crossed into another branch
                                nextTrim = strtrim(rewLines{li2});
                                if ~isempty(regexp(nextTrim,'^(elseif|else(\s|%|$)|if |end\b)','once'))
                                    break;
                                end
                                ulTok = regexp(rewLines{li2},'uL_per_rew\s*=\s*([\d.]+)','tokens','once');
                                if ~isempty(ulTok)
                                    procData.ulPerRew = str2double(ulTok{1});
                                    break;
                                end
                            end
                            if ~isnan(procData.ulPerRew); break; end
                        end
                    end
                % --- entering an else block ---
                elseif ~isempty(regexp(strtrim(ln),'^else(\s|%|$)','once'))
                    inElse = true;
                % --- leaving else block on next if/elseif/end ---
                elseif ~isempty(regexp(strtrim(ln),'^(if |elseif |end\b)','once'))
                    inElse = false;
                end
                % --- capture uL_per_rew inside else block ---
                if inElse
                    ulTok = regexp(ln,'uL_per_rew\s*=\s*([\d.]+)','tokens','once');
                    if ~isempty(ulTok)
                        elseUL(end+1) = str2double(ulTok{1}); %#ok<AGROW>
                        inElse = false;
                    end
                end
            end
            % Fallback: if all standard-rig else values agree, use that
            if isnan(procData.ulPerRew) && ~isempty(elseUL)
                uniUL = unique(elseUL);
                if length(uniUL) == 1
                    procData.ulPerRew = uniUL;
                end
            end
        end
    end
end

% Parse TmazeMoveTowerVisGuide.m for special reward scheme.
% Identifies whether mouse is in bigRewardMice (big reward every non-crutch
% correct trial) or bigRewardStreakMice (big reward every Nth non-crutch correct).
% NOTE: if a mouse should be detected here, ensure it is listed in the
% appropriate array in TmazeMoveTowerVisGuide.m (e.g. vr.bigRewardMice = [37,...]).
if ~isempty(dataCell)
    mouseNum_rew = dataCell{1}.info.mouse;
    procData.specialRewardScheme = 'N/A';
    virmenFile2 = which('TmazeMoveTowerVisGuide');
    if ~isempty(virmenFile2)
        fid = fopen(virmenFile2,'r');
        if fid > 0
            schemeLines = {};
            tline = fgetl(fid);
            while ischar(tline)
                schemeLines{end+1} = tline; %#ok<AGROW>
                tline = fgetl(fid);
            end
            fclose(fid);
            bigRewMice       = [];
            bigRewStreakMice  = [];
            bigRewUL         = NaN;
            bigRewInterval   = NaN;
            for li = 1:length(schemeLines)
                tok = regexp(schemeLines{li},'vr\.bigRewardMice\s*=\s*\[([^\]]*)\]','tokens','once');
                if ~isempty(tok)
                    v = str2num(['[' tok{1} ']']); %#ok<ST2NM>
                    if ~isempty(v); bigRewMice = v; end
                end
                tok = regexp(schemeLines{li},'vr\.bigRewardStreakMice\s*=\s*\[([^\]]*)\]','tokens','once');
                if ~isempty(tok)
                    v = str2num(['[' tok{1} ']']); %#ok<ST2NM>
                    if ~isempty(v); bigRewStreakMice = v; end
                end
                tok = regexp(schemeLines{li},'vr\.BigReward\s*=\s*([\d.]+)','tokens','once');
                if ~isempty(tok); bigRewUL = str2double(tok{1}); end
                tok = regexp(schemeLines{li},'vr\.bigRewardStreakInterval\s*=\s*([\d.]+)','tokens','once');
                if ~isempty(tok); bigRewInterval = str2double(tok{1}); end
            end
            muSign = char(181);                    % µ  (U+00B5)
            supTH  = [char(7511) char(688)];       % ᵗʰ (U+1D57 U+02B0)
            if ismember(mouseNum_rew, bigRewMice)
                procData.specialRewardScheme = sprintf(['%g' muSign 'L (Every Correct NC)'], bigRewUL);
            elseif ismember(mouseNum_rew, bigRewStreakMice)
                procData.specialRewardScheme = sprintf(['%g' muSign 'L (%g' supTH ' Correct NC)'], bigRewUL, bigRewInterval);
            end
        end
    end
end

% familiarFac + novel trial stats.
% All four fields (familiarFac, nNonFamiliar, nRewNonFamiliar, percCorrNonFamiliar)
% are shown ONLY when the current mouse is listed in the ismember() call in
% TmazeMoveTowerVisGuide.m. BAS locates that file automatically via which().
% No manual maintenance required here — update only TmazeMoveTowerVisGuide.m.
if ~isempty(dataCell) && isfield(dataCell{1},'visStim') && isfield(dataCell{1}.visStim,'isFamiliar')
    mouseInFamiliarExp = false;  % default: not in familiar/novel experiment
    mouseNum = dataCell{1}.info.mouse;

    % --- For new sessions: familiarFac was saved directly by VirMEn ---
    if isfield(dataCell{1}.maze,'familiarFac')
        procData.familiarFac = dataCell{1}.maze.familiarFac;
        mouseInFamiliarExp   = true;

    % --- For old sessions: parse TmazeMoveTowerVisGuide.m to get the list ---
    else
        virmenFile = which('TmazeMoveTowerVisGuide');
        if ~isempty(virmenFile)
            fid = fopen(virmenFile,'r');
            if fid > 0
                allLines = {};
                tline = fgetl(fid);
                while ischar(tline)
                    allLines{end+1} = tline; %#ok<AGROW>
                    tline = fgetl(fid);
                end
                fclose(fid);
                % Search for: ismember(vr.mouseNum,[...]) followed by familiarFac = X
                for li = 1:length(allLines)-1
                    if ~isempty(regexp(allLines{li},'ismember.*mouseNum','once')) && ...
                       ~isempty(regexp(allLines{li+1},'familiarFac','once'))
                        miceToken = regexp(allLines{li},'\[([^\]]*)\]','tokens','once');
                        valToken  = regexp(allLines{li+1},'familiarFac\s*=\s*([\d.]+)','tokens','once');
                        if ~isempty(miceToken) && ~isempty(valToken)
                            miceList = str2num(['[' miceToken{1} ']']); %#ok<ST2NM>
                            if ismember(mouseNum, miceList)
                                procData.familiarFac = str2double(valToken{1});
                                mouseInFamiliarExp   = true;
                            end
                        end
                        break;
                    end
                end
            end
        end
    end

    % Novel stats — only computed when mouse is in the familiar/novel experiment
    if mouseInFamiliarExp
        procData.nNonFamiliar    = sum(findTrials(dataCell,'visStim.isFamiliar==0'));
        procData.nRewNonFamiliar = sum(findTrials(dataCell,'visStim.isFamiliar==0; result.correct==1'));
        if procData.nNonFamiliar > 0
            procData.percCorrNonFamiliar = 100 * procData.nRewNonFamiliar / procData.nNonFamiliar;
        else
            procData.percCorrNonFamiliar = NaN;
        end
    end
end

