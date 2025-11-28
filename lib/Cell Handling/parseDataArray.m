function dataCell = parseDataArray(dataCell,data,exper)
%parseDataArray.m function to get section of data array corresponding to
%that trial and place in dataCell structure under data{}.dat
%
%trial bounds specified by ITI specifier and includes all columns in which
%ITI == 0 plus the first column in which ITI == 1

%get trial start and stop indices

if isfield(exper.variables,'inITI_ind')
    inITI_ind = str2double(exper.variables.inITI_ind);
else
    inITI_ind = size(data,1);
end
tStarts = [1 find(diff(data(inITI_ind,:)) == -1) + 1]; %find trial starts and add first column to account for first trial
tStops = find(diff(data(inITI_ind,:)) == 1) + 1; %find trial stop

%check to see if last trial completed
if length(tStarts) > length(tStops) %if more starts than stops
    tStarts = tStarts(1:end-1);
    if length(tStarts) > length(tStops)
        error('Multiple incomplete trials');
    end
elseif length(tStarts) < length(tStops)
    error('Trial starts missing');
end

%check to make sure nTrials in data array matches nTrials in dataCell
if length(tStarts) > length(dataCell)
    disp('nTrials in data array is greater than nTrials in dataCell');
elseif length(tStarts) < length(dataCell)
    disp('nTrials in data array is less than nTrials in dataCell');
elseif length(tStarts) == length(dataCell) - 1
    dataCell = dataCell(1:end-1);
end

for i = 1:length(dataCell) %for each trial
    dataCell{i}.dat = data(:,tStarts(i):tStops(i)); %save data array portion
end


end