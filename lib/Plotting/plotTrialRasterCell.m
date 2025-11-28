function [guiObjects] = plotTrialRasterCell(dataCell,data,procData,guiObjects,dataTrials)
%plotTrialRasterCell.m Plots raster of trials in gui
%
%ASM 9/19/12 edited 7/3/13
set(0,'CurrentFigure',guiObjects.figHandle); %set current figure to background by directly accessing current figure property

if iscell(data) %if multiple data sets
    totTime = 0;
    timeVec = [];
    totTimeDNum = 0;
    for i=1:length(data)
        totTime = totTime + size(data{i},2);
        procTime = data{i}(1,:)-data{i}(1,1);
        if ~isempty(timeVec)
            procTime = procTime + max(timeVec);
        end
        timeVec = [timeVec procTime];
    end
    cumDataTrials = cumsum(dataTrials);
else
    totTime = size(data,2);
    timeVec = data(1,:)-data(1,1);
    cumDataTrials = cumsum(dataTrials);
    data = {data};
end

%plot trial conditions
guiObjects.trialRaster = subplot('Position',[0.05 0.65 0.9 0.03]);
cla reset;
xlabel('Window End Time'); %set xlabel
set(gca,'YTickLabel','','YTick',[]); %delete y ticks
load('MyColormaps.mat','blackGreyColor'); %load custom colormap
if ~isempty(dataCell)
    nConds = length(dataCell{1}.info.conditions);
    if length(unique(getCellVals(dataCell,'maze.condition'))) > nConds
        nConds = length(unique(getCellVals(dataCell,'maze.condition')));
    end
    cmapCustom = blackGreyColor(round(linspace(1,size(blackGreyColor,1),...
        nConds)),:); %#ok<NODEF> %set colormap 
else
    cmapCustom = blackGreyColor(round(linspace(1,size(blackGreyColor,1),4)),:);
end
%plot overlaid variables
guiObjects = plotDelayLength(procData,totTime,guiObjects);
guiObjects = plotGreyFac(procData,totTime,guiObjects);
guiObjects = plotTwoFac(procData,totTime,guiObjects);
guiObjects = plotMazeLength(procData,totTime,guiObjects);

guiObjects.rasterHandle = zeros(size(dataCell));
guiObjects.shadeHandle = zeros(size(dataCell));
guiObjects.shadeHandle2 = zeros(size(dataCell));
rasterLocation = zeros(size(dataCell));
yBounds = get(gca,'ylim');
newCellFlag = false;
for i=1:size(dataCell,2)
    dataInd = find(i <= cumDataTrials,1,'first');
    ind = find(dataCell{i}.time.stop >= data{dataInd}(1,:),1,'last'); %find the last point at which the stop time is greater
    totPrevInd = 0;
    for j=1:dataInd-1
        totPrevInd = totPrevInd + size(data{j},2);
    end
    ind = ind + totPrevInd;

    if i==1 && i~=size(dataCell,2)
        halfInd(1) = 1;
        halfInd(2) = ind + (find(dataCell{i+1}.time.stop >= data{dataInd}(1,:),1,'last') - ind)/2;
    elseif i~=1 && i==size(dataCell,2)
        halfInd(1) = ind - (ind - find(dataCell{i-1}.time.stop >= data{dataInd}(1,:),1,'last'))/2;
        halfInd(2) = totTime;
    elseif i==1 && i==size(dataCell,2)
        halfInd(1) = 1;
        halfInd(2) = totTime;
    elseif newCellFlag
        halfInd(1) = ind - (ind - pastInd)/2;
        halfInd(2) = ind + (totPrevInd + find(dataCell{i+1}.time.stop >= data{dataInd}(1,:),1,'last') - ind)/2;
        newCellFlag = false;
    elseif ismember(i,cumDataTrials)
        newCellFlag = true;
        pastInd = ind;
        halfInd(1) = ind - (ind - find(dataCell{i-1}.time.stop >= data{dataInd}(1,:),1,'last'))/2;
        halfInd(2) = ind + ((size(data{dataInd},2)-ind) + find(dataCell{i+1}.time.stop >= data{dataInd+1}(1,:),1,'last'))/2;
    else
        halfInd(1) = ind - (ind - find(dataCell{i-1}.time.stop >= data{dataInd}(1,:),1,'last'))/2;
        halfInd(2) = ind + (totPrevInd + find(dataCell{i+1}.time.stop >= data{dataInd}(1,:),1,'last') - ind)/2;
    end
    
    if ismember(i,cumDataTrials)
        newCellFlag = true;
        pastInd = ind;
    else
        newCellFlag = false;
    end
    
    halfInd = halfInd/totTime;
    % correct/error indicator
    if dataCell{i}.result.correct
        guiObjects.shadeHandle(i) = patch([halfInd(1) halfInd(2) halfInd(2) halfInd(1)],...
            [yBounds(2) yBounds(2) yBounds(1)+0.8*(yBounds(2)-yBounds(1)) yBounds(1)+0.8*(yBounds(2)-yBounds(1))],...
            [0.18 0.8 0.44],'EdgeColor','none');
    else
        guiObjects.shadeHandle(i) = patch([halfInd(1) halfInd(2) halfInd(2) halfInd(1)],...
            [yBounds(2) yBounds(2) yBounds(1)+0.8*(yBounds(2)-yBounds(1)) yBounds(1)+0.8*(yBounds(2)-yBounds(1))],...
            [0.9 0.36 0.36],'EdgeColor','none');
    end
    % stim/non-stim indicator
    if isfield(dataCell{i},'stim')
        if dataCell{i}.stim.power > 0
            guiObjects.shadeHandle2(i) = patch([halfInd(1) halfInd(2) halfInd(2) halfInd(1)],...
                [yBounds(1)+0.8*(yBounds(2)-yBounds(1)) yBounds(1)+0.8*(yBounds(2)-yBounds(1)) yBounds(1)+0.6*(yBounds(2)-yBounds(1)) yBounds(1)+0.6*(yBounds(2)-yBounds(1))],...
                [0.5 0 0.9],'EdgeColor','none');
        else
            guiObjects.shadeHandle2(i) = patch([halfInd(1) halfInd(2) halfInd(2) halfInd(1)],...
                [yBounds(1)+0.8*(yBounds(2)-yBounds(1)) yBounds(1)+0.8*(yBounds(2)-yBounds(1)) yBounds(1)+0.6*(yBounds(2)-yBounds(1)) yBounds(1)+0.6*(yBounds(2)-yBounds(1))],...
                [1,1,1],'EdgeColor','none');
        end
    end
    guiObjects.rasterHandle(i) = line([ind/totTime ind/totTime],[yBounds(1) yBounds(1)+.8*(yBounds(2)-yBounds(1))]);
    set(guiObjects.rasterHandle(i),'ButtonDownFcn',{@rasterClick_CALLBACK,...
        dataCell,i});
    rasterLocation(i) = ind/totTime;
    set(guiObjects.rasterHandle(i),'Color',cmapCustom(dataCell{i}.maze.condition+1,:),'LineWidth',3);
end
xlim([0 1]);
xTickVals = num2cell(timeVec(round(linspace(1,length(timeVec),11))));
xTickDates = cellfun(@(x) datestr(x,'HH:MM:SS'),xTickVals,'UniformOutput',false);
set(gca,'XTickLabel',xTickDates);

%reverse object draw order
set(gca,'children',flipud(get(gca,'children')));

%create trial cond legend
if isfield(guiObjects,'trialCondLegend') && ishandle(guiObjects.trialCondLegend)
    delete(guiObjects.trialCondLegend);
end
guiObjects.trialCondLegend = subplot('Position',[0.02 0.6025 0.9 0.0175]);
set(gca,'visible','off');
xlim([0 1]);
for i = 1:size(cmapCustom,1)
    line([i/24 i/24],[0 1],'Color',cmapCustom(i,:),'LineWidth',3);
    text(.0417*i+.01,.5,num2str(i),'Color',cmapCustom(i,:),'HorizontalAlignment','Left');
end

set(guiObjects.trialRaster,'UserData',timeVec);
set(guiObjects.trialRaster,'ButtonDownFcn',{@rasterAxesClick_CALLBACK,...
    dataCell,guiObjects,rasterLocation});
end

function rasterAxesClick_CALLBACK(src,evnt,dataCell,guiObjects,rasterLocation)
%function to show dataCell when raster is clicked 

%get click location
clickLoc = get(guiObjects.trialRaster,'CurrentPoint');

%get x coordinate
xClick = clickLoc(1,1);

%find nearest raster
diffLoc = abs(rasterLocation - xClick);
[~,ind] = min(diffLoc);

plotTrialVals(dataCell,ind);
end

function rasterClick_CALLBACK(src,evnt,dataCell,ind)
%function to show dataCell when raster is clicked 

plotTrialVals(dataCell,ind);
end

function plotTrialVals(dataCell,ind)
%generate figure
strucFig = figure('Name',['Trial ' num2str(ind)],'NumberTitle','Off','MenuBar','none','Color',[1 1 1]);
screens = get(0,'MonitorPositions');
if size(screens,1) > 1
    scrn = screens(2,:);
else
    scrn = screens(1,:);
end
set(strucFig,'OuterPosition',[scrn(1)+0.5*(scrn(3)-scrn(1)) 0.2*(scrn(4)-scrn(2))...
    0.3*(scrn(3)-scrn(1)) 0.6*(scrn(4)-scrn(2))]); %set position

%create strucuture tree
createStrucTree(dataCell{ind},true,ind);
end

function guiObjects = plotDelayLength(procData,totTime,guiObjects)
%%% plot delay length
if isfield(procData,'delayLengthAll') %if delayLengthAll exists
    hold on;
    xTimes = (1:totTime)/totTime; %create xTimes
    guiObjects.delayLengthPlot = plot(xTimes,procData.delayLengthAll,'b','LineWidth',2);
    if min(procData.delayLengthAll) == max(procData.delayLengthAll)
        ylim([min(procData.delayLengthAll) min(procData.delayLengthAll)+1]);
        set(gca,'YTickLabel',{num2str(min(procData.delayLengthAll)),...
            num2str(min(procData.delayLengthAll)+ 1)},...
            'YTick',[min(procData.delayLengthAll), min(procData.delayLengthAll)+1],...
            'YAxisLocation','right');
    else
        ylim([min(procData.delayLengthAll) max(procData.delayLengthAll)]);
        set(gca,'YTickLabel',{num2str(min(procData.delayLengthAll)),...
            num2str(max(procData.delayLengthAll))},...
            'YTick',[min(procData.delayLengthAll), max(procData.delayLengthAll)],...
            'YAxisLocation','right');
    end
end
end

function guiObjects = plotGreyFac(procData,totTime,guiObjects)
%%% plot greyFac
if isfield(procData,'greyFacAll') %if greyFacAll exists
    hold on;
    xTimes = (1:totTime)/totTime; %create xTimes
    guiObjects.greyFacPlot = plot(xTimes,procData.greyFacAll,'b','LineWidth',2);
    if min(procData.greyFacAll) == max(procData.greyFacAll)
        ylim([min(procData.greyFacAll) min(procData.greyFacAll)+0.01]);
        set(gca,'YTickLabel',{num2str(min(procData.greyFacAll)),...
            num2str(min(procData.greyFacAll)+0.01)},...
            'YTick',[min(procData.greyFacAll), min(procData.greyFacAll)+0.01],...
            'YAxisLocation','right');
    else
        ylim([min(procData.greyFacAll) max(procData.greyFacAll)]);
        set(gca,'YTickLabel',{num2str(min(procData.greyFacAll)),...
            num2str(max(procData.greyFacAll))},...
            'YTick',[min(procData.greyFacAll), max(procData.greyFacAll)],...
            'YAxisLocation','right');
    end
end
end

    % added by SK 04/23/15
function guiObjects = plotTwoFac(procData,totTime,guiObjects)
%%% plot greyFac
if isfield(procData,'twoFacAll') %if twoFacAll exists
    hold on;
    xTimes = (1:totTime)/totTime; %create xTimes
    guiObjects.greyFacPlot = plot(xTimes,procData.twoFacAll,'b','LineWidth',2);
    if min(procData.twoFacAll) == max(procData.twoFacAll)
        ylim([min(procData.twoFacAll) min(procData.twoFacAll)+0.01]);
        set(gca,'YTickLabel',{num2str(min(procData.twoFacAll)),...
            num2str(min(procData.twoFacAll)+0.01)},...
            'YTick',[min(procData.twoFacAll), min(procData.twoFacAll)+0.01],...
            'YAxisLocation','right');
    else
        ylim([floor(min(procData.twoFacAll)*10)/10 max(procData.twoFacAll)]);
        set(gca,'YTickLabel',{num2str(min(procData.twoFacAll)),...
            num2str(max(procData.twoFacAll))},...
            'YTick',[min(procData.twoFacAll), max(procData.twoFacAll)],...
            'YAxisLocation','right');
    end
end
end

function guiObjects = plotMazeLength(procData,totTime,guiObjects)
%%% plot mazeLength
if isfield(procData,'mazeLengthAll') %if greyFacAll exists
    hold on;
    xTimes = (1:totTime)/totTime; %create xTimes
    guiObjects.mazeLengthPlot = plot(xTimes,procData.mazeLengthAll,'b','LineWidth',2);
    if min(procData.mazeLengthAll) == max(procData.mazeLengthAll)
        ylim([min(procData.mazeLengthAll) min(procData.mazeLengthAll)+0.01]);
        set(gca,'YTickLabel',{num2str(min(procData.mazeLengthAll)),...
            num2str(min(procData.mazeLengthAll)+0.01)},...
            'YTick',[min(procData.mazeLengthAll), min(procData.mazeLengthAll)+0.01],...
            'YAxisLocation','right');
    else
        ylim([min(procData.mazeLengthAll) max(procData.mazeLengthAll)]);
        set(gca,'YTickLabel',{num2str(min(procData.mazeLengthAll)),...
            num2str(max(procData.mazeLengthAll))},...
            'YTick',[min(procData.mazeLengthAll), max(procData.mazeLengthAll)],...
            'YAxisLocation','right');
    end
end
end