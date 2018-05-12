function filtscan = flattenScan(filtscan,xorder,yorder)

numcants=size(filtscan,1);
numlines=size(filtscan,3);
numpts=size(filtscan,4);

if(matlabpool('size') == 0)
        matlabpool % Start parallel iterations
end

% X Flatten
if(xorder > 0)
    parfor c=1:numcants
        for t=1:2
            for L=1:numlines           
                lineonly = zeros(numpts,1);
                lineonly(:) = filtscan(c,t,L,:);
                linsub = polyval(polyfit(1:numpts,lineonly',xorder),1:numpts);
                filtscan(c,t,L,:) = lineonly - linsub';
            end
        end
    end
end

% Y Flatten
if(yorder>0)
    if(yorder > 1)
        disp('I dont know how to flatten with higher order on Y axis YET');
        disp('Switching to 1st order polynomial for subtracting slope only');
        yorder=1;
    end
    parfor c=1:numcants
        for t=1:2
            for L=1:numpts         
                lineonly = zeros(numlines,1);
                lineonly(:) = filtscan(c,t,:,L);
                p = polyfit(1:numlines,lineonly',yorder);
                % Take only the slope:
                % UNTESTED SECTION:
                linsub = polyval([p(1),0],1:numlines);
                % Subtracting the entire line will leave the entire scan
                % flat. Need to preserve the offset. Probably only possible
                % by subtracting the slope. This would mean only 1st order
                % Y axis flattens.
                filtscan(c,t,:,L) = lineonly - linsub';
            end
        end
    end
end

end