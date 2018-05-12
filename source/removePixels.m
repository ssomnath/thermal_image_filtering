function data2 = removePixels(data,pixToRem)
    % Add 1 pixel per floor(numpix/pixToAdd) pixels
    data2 = zeros(size(data,1),size(data,2),size(data,3),size(data,4)-pixToRem);
    indicesAtWhichToRem = (floor(size(data,4)/pixToRem).*(0:pixToRem-1))+1;
    
    for c=1:size(data,1)
        for t=1:2
            j=1;
            n=1;
            for i=1:size(data,4)
                if(i~=indicesAtWhichToRem(min(pixToRem,n)))
                    data2(c,t,:,j) = data(c,t,:,i);
                    j=j+1;
                    n=n+1;
                end
            end
        end
    end
end