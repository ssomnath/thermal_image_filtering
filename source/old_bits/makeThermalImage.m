function filtscan = makeThermalImage(data,av)
    
    %% 1: Discard first and last scan line data
    fst = find(data(:,1),1,'first');
    numlines = max(data(:,1))-1;
    lst = min(find(data(:,1)==(numlines+1)));
    
    % Discarding the first column since:
    % The line data has been collected but there may be some lines 
    % with more or some with less points. This is like taking an 
    % average to make sure that all lines have same number of points
    data = data(fst:lst,2:6);
    
    %% 2: Filter  data
    
    filtdata = zeros(5,floor(size(data,1)/av));
    
    for c=1:5 
        j=1; 
        for i=1+(av/2):av:size(data,1)
            temp=sum(data((i-(av/2)):min(size(data,1),i+(av/2)),c));
        	filtdata(c,j)=temp/av;
            j=j+1;
        end
    end
     
    % Discard last point:
    filtdata = filtdata(:,1:length(filtdata)-1);
    
    % release unused memory
    clear('data','av','fst','lst','i','j','temp');
    
    %% 3: Reshape data to 2D form:
    
    numpts = floor(size(filtdata,2)/numlines);
    
    filtscan = zeros(5,numlines,numpts);
    
    % reshape is acting wierd or I don't know how to use it correctly.
    % manually chop data
    for c=1:5
        for L=1:numlines
            filtscan(c,L,:) = filtdata(c,(L-1)*numpts+1:L*numpts);
        end
    end
    
    % release unused memory
    clear('filtdata','c','L');
    
    %% 4: Planefit the data:
    
    % Quadratic fit for points
    
    for c=1:5
        for L=1:numlines
            lineonly = zeros(numpts,1);
            lineonly(:) = filtscan(c,L,:);
            linsub = polyval(polyfit(1:numpts,lineonly',2),1:numpts);
            filtscan(c,L,:) = lineonly - linsub';
        end
    end
    
    % linear fit the lines
    
    % release unused memory
    clear('c','L','lineonly','linesub');
    
    %% 5: Chop again into trace and retrace
    
    
    %% 6: Display graphs:
    
    temp = zeros(numlines,numpts);
    figure(1);
    for i=1:5
        temp(:,:) = filtscan(i,:,:);
        subplot(2,3,i);
        contourf(temp);
        colorbar;
        xlabel('X');ylabel('Y');
        title(strcat('Thermal Singnal from Cantilever #_',num2str(i)));
    end
    
    
    %% 7: Write data to spreadsheet:
    
    % Excel will not allow such large writes. Transfer manually.
    
end