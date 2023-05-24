%% Code Information
%*************************************************************************
%Stanford GPS

%Function Description: Find Decision Boundary for a set of data using
%Support Vector Machine (SVM)
%*************************************************************************    


function [c]=FitModel(layerdata,altitude,origin,box_x,box_y)
    n=1000;
    %Organize Data
    Tbl=layerdata(:,ismember(layerdata.Properties.VariableNames, ...
        {'x','y'})); %Add 'Weights' later on
    Y=double(layerdata.nic<=7); 
    %Create Meshgrid
    x=linspace(box_x(1),box_x(2),n);
    y=linspace(box_y(1),box_y(2),n);
    [xGrid,yGrid] = meshgrid(x,y);
    xGrid_total = [xGrid(:),yGrid(:)];
    %Fit model to data
    model=fitcsvm(Tbl,Y,'ClassNames',[0 1],'Standardize',true,...
        'KernelFunction','rbf','BoxConstraint',1);
    [~,scores] = predict(model,xGrid_total);
    %Convert contours from ENU to LLA coordinate system
    [x_lla,y_lla]=ContourConvert(x,y,n,altitude,origin);
    %Gather contour data
    boundary=(reshape(scores(:,2),[n,n]));
    c=contourc(x_lla,y_lla,boundary,[0 0]);
    %Replace levels with designated altitude
    %find where it is 0, put altitude index below that
end

%% Other Functions
%Convert Grid from ENU to LLA, reformat back into meshgrid (in LLA)
function [x_lla,y_lla]=ContourConvert(x,y,n,altitude,origin)
%     x_vec=reshape(xgrid,[n^2,1]);
%     y_vec=reshape(ygrid,[n^2,1]);
    lladata=enu2lla([x',y',altitude*ones(n,1)],origin','ellipsoid');
    x_lla=lladata(:,2);
    y_lla=lladata(:,1);
%     xGrid_lla=reshape(lladata(:,2),[n,n]);
%     yGrid_lla=reshape(lladata(:,1),[n,n]);
end