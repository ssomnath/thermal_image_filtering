function data2 = addPixels(data,pixToAdd)
    % Add 1 pixel per floor(numpix/pixToAdd) pixels
    data2 = zeros(size(data,1),size(data,2),size(data,3),size(data,4)+pixToAdd);
    indicesAtWhichToAdd = (floor(size(data,4)/pixToAdd).*(0:pixToAdd-1))+1;
    
    for c=1:size(data,1)
        for t=1:2
            j=1;
            n=1;
            for i=1:size(data,4)
                data2(c,t,:,j) = data(c,t,:,i);
                j=j+1;
                if(i==indicesAtWhichToAdd(min(pixToAdd,n)))
                    data2(c,t,:,j) = 0.5.*(data(c,t,:,i)+data(c,t,:,i+1));
                    j=j+1;
                    n=n+1;
                end
            end
        end
    end
end