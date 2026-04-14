function updateTableCell(table,guiObjects)
%updateTableCell.m This function updates the table for the gui

%get most up to date guiObjects
guiObjects = get(guiObjects.figHandle,'UserData');

values = get(guiObjects.tableList,'Value');

for i=1:length(table)
   tableData{i} = table{i}.sessionTime.data;
    rowNames = table{i}.sessionTime.names;
    if ismember(2,values) %general
        tableData{i} = cat(1,tableData{i},num2cell(table{i}.general.data));
        rowNames = cat(2,rowNames,table{i}.general.names);
    end
    if ismember(1,values) %special
        tableData{i} = cat(1,tableData{i},num2cell(table{i}.special.data));
        rowNames = cat(2,rowNames,table{i}.special.names);
    end
    if ismember(3,values) %conditions
        tableData{i} = cat(1,tableData{i},num2cell(table{i}.conditions.data));
        rowNames = cat(2,rowNames,table{i}.conditions.names);
    end
    if ismember(4,values) %timing
        tableData{i} = cat(1,tableData{i},num2cell(table{i}.timing.data)); %#ok<*AGROW>
        rowNames = cat(2,rowNames,table{i}.timing.names);
    end
    
    columnWidth = cell(1,size(table{i}.general.data,2));
    columnNames = cell(1,size(table{i}.general.data,2));
end

for i=1:length(table)
    columnWidth{i} = 101;
    if i==1
        columnNames{i} = 'All Data';
        offset = 1;
    elseif table{1}.lastX && i == 2
        columnNames{i} = ['Last ',num2str(table{1}.lastXNum),' Trials'];
        offset = 2;
    else
        columnNames{i} = ['Condition ',num2str(table{i}.vals(i-offset))];
    end
end

catTableData = {};
for i=1:length(tableData)
    catTableData = cat(2,catTableData,tableData{i});
end

set(guiObjects.table,'Data',catTableData,'RowName',rowNames,...
    'ColumnWidth',columnWidth,'ColumnName',columnNames);

%save guiObjects
set(guiObjects.figHandle,'UserData',guiObjects);
