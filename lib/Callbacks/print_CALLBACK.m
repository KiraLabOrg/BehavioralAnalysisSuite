function print_CALLBACK(src,evnt,guiObjects)
        
    % configure the saving directory
    mouseID = guiObjects.figHandle.UserData.anName;
    CurrentMiceInd = strfind(guiObjects.userData.path,'\Current Mice');
    figpath = [guiObjects.userData.path,'BASfigs\',mouseID,'\'];
    % figpath = [guiObjects.userData.path(1:CurrentMiceInd),'BASfigs\',mouseID,'\'];

    % configure the saving file name
    if isfield(guiObjects.animalPopup.UserData,'fileCell') % loaded data
        loadedFileName = guiObjects.animalPopup.UserData.fileCell{guiObjects.animalPopup.UserData.loadedFile};
        % CellInd = strfind(loadedFileName,'_Cell');
        % fig_name = loadedFileName(1:CellInd-1);
        fig_name = strrep(loadedFileName, '_Cell', '');
        fig_name = strrep(fig_name, '.mat', '');
    else % live data
        mouseID = guiObjects.figHandle.UserData.anName;
        fig_name = [mouseID,'_',guiObjects.figHandle.UserData.dateName];
        k = 0;
        new_fig_name = fig_name;
        while exist([figpath,new_fig_name,'.png'],'file')
            k = k+1;
            new_fig_name = [fig_name,'_',num2str(k)];
        end
        fig_name = new_fig_name;
    end
    
    fig_date = fig_name(7:12);
    figpath2 = [guiObjects.userData.path,'BASfigs\Daily\',fig_date,'\'];
    
    if ~exist(figpath,'dir')
        mkdir(figpath);
    end
    
    if ~exist(figpath2,'dir')
        mkdir(figpath2);
    end
    
    export_fig(gcf,[figpath,fig_name],'-png')
    copyfile([figpath,fig_name,'.png'],[figpath2,fig_name,'.png'])

end