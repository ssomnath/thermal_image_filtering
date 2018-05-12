function flat = myflatten(data)
    % Given data is 2D. Flatten it on both axes
    
    %X flatten
    flat = zeros(size(data));
    numpts = size(data,2);
    numlines = size(data,1);
    for i=1:numlines
        linsub = polyval(polyfit(1:numpts,data(i,:),2),numpts);
        flat(i,:) = data(i,:) - linsub;
    end
    
    %Y flatten
    % use quadratic fit.
    for i=1:numpts
        linsub = polyval(polyfit(1:numlines,data(:,i)',2),numlines);
        flat(:,i) = data(:,i) - linsub;
    end
    
    figure(9);
    surf(flat);
end