function filtscan = mycont(data,av)
    
    %% 1: Discard first and last scan line data
    fst = find(data(:,1),1,'first');
    numlines = max(data(:,1))-1;
    lst = min(find(data(:,1)==(numlines+1)));
    
    % Discarding the first column since:
    % The line data has been collected but there may be some lines 
    % with more or some with less points. This is like taking an 
    % average to make sure that all lines have same number of points
    data = data(fst:lst,2:6);
    
    %% 2: Convert to 2D scan areas
    
    numpts = floor((lst-fst)/numlines);
    
    rawscan = zeros(5,numlines,numpts);
    
    %Why are there more gratings than there should be within each line?
    for i=1:5
        rawscan(i,:,:) = reshape(data(1:(numpts*numlines),i),numlines,numpts);
    end
    
    % release unused memory
    clear('data','fst','lst');
    
   %% 3: Filter  data
    
    newnumpts = floor(numpts/av);
    filtscan = zeros(5,numlines,newnumpts);
    
    % need to filter for all 1) cant 2) line 3) pixels within line
    
    for c=1:5
        for L=1:numlines
            
            j = 1;
            for i=1+(av/2):av:numpts
                temp=sum(rawscan(c,L,(i-(av/2)):min(numpts,i+(av/2))));
                filtscan(c,L,j)=temp/av;
                j=j+1;
            end
            
            % Quadratic line fit:
            lineonly = zeros(newnumpts,1);
            lineonly(:) = filtscan(c,L,:);
            linsub = polyval(polyfit(1:newnumpts,lineonly',2),1:newnumpts);
            filtscan(c,L,:) = lineonly - linsub';
            
        end
    end
    
    % release unused memory
    clear('rawscan','lineonly','linsub');
    
    %% 4: Y-Plane-fit data
   
    
    %% 5: Present data
    %figure(1);surf(rawscan(1,:,:));
end