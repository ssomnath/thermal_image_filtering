function filtscan = makeThermalImage2(data,av,flatten)
%% 1: Discard first and last sections of 1D data:
% floor to get ints on trigger channel
[rawrows,rawcols] = size(data);
numcants = rawcols-1;
% Last column contains the trigger channel
trig = zeros(rawrows,1);
trig(:,:) = data(:,rawcols);
%plot(1:length(trig),trig);hold on;
trig = floor(trig);
%plot(1:length(trig),trig,'r');

% discard up to first instance of 2 and after last instance of 8
fst = min(find(trig==2));
lst = max(find(trig==8));
if(fst==0 || lst==0)
    disp('Trigger channel error');
    return;
end
trig = trig(fst:lst);
data = data(fst:lst,1:numcants);



% There are bound to be some values that are in between the trigger values
% Due to the slow response of the DAC. Perform the role of a comparator
% by raising that value to the next trigger value.
% values go like this:
% 2 before trace
% 4 for trace
% 6 between trace and retrace
% 8 for retrace
% 2 after retrace

% Also, need to count number of lines so that raw scan data can be divided
% into trace and retrace accordingly

rising=1; % flag
numlines=0;
prev=2;
for i=1:length(trig)
    if(trig(i)==5 || trig(i) == 3 || trig(i) == 7)
        if(rising == 1)
            trig(i)=trig(i)+1;
        else
            % Not the most accurate but safest
            trig(i)=trig(i-1);
        end
    end
    if(trig(i)==1)
        trig(i)=2;
    end
    
    if(prev~=trig(i))
        prev=trig(i);
        switch(trig(i))
            case 2
                % retrace just ended
                rising = 1; 
            case 8
                % retrace just started
                numlines = numlines+1;
                rising = 0;
        end
    end
end

%plot(1:length(trig),trig,'g');

%conservative estimate for size of trace and retrace = 0.5 * (lst-fst);

%% 2: Resize the 1D array into 2D trace and retracescans
% New array size = 5cantsx2(tr+retr)x(truncated length/2)
% loop over raw 1D array keep looking at last column

rawscan = zeros(numcants, 2, numlines, floor(size(data,1)/(2*numlines)));

lineindex=1;
pixelindex=1;
prev=0;
maxpixel = zeros(1,numlines);
for i=1:length(trig)
    if(trig(i)==4 || trig(i)==8)
        temp=1;
        if(trig(i)==4)
            % Trace
            if(prev==1)
                lineindex=lineindex+1;
                pixelindex=1;
                prev=0;
            end

        elseif(trig(i)==8)
            if(prev==0)
                pixelindex=1;
                prev=1;
            end
            temp=2;
        end
        
        for j=1:numcants
            rawscan(j,temp,lineindex,pixelindex) = data(i,j);   
        end
        pixelindex=pixelindex+1;
        maxpixel(lineindex)=pixelindex;
    end
end

%Some lines have more pixels than others. Discarding extra:
rawscan = rawscan(:,:,:,1:min(maxpixel));

%release unused memory:
clear('data','trig','maxpixel')
clear('fst','lst','i','j','lineindex','pixelindex','prev','rawcols','rawrows','rising','temp');

%% 3: Filter data

%av = floor(size(rawscan,4)/1025)
filtscan = zeros(numcants, 2, numlines, floor(size(rawscan,4)/av));

for c=1:numcants
    for t=1:2
        for L=1:numlines
            j=1;
            for i=1+(av/2):av:size(rawscan,4)
                temp=sum(rawscan(c,t,L,i-(av/2):min(size(rawscan,4),i+(av/2))));
                filtscan(c,t,L,j)=temp/av;
                j=j+1;
            end
            
            % Line filtering is now over - perform flattening:
            if(flatten==1)
                flatpoints = size(filtscan,4)-1;
                lineonly = zeros(flatpoints,1);
                lineonly(:) = filtscan(c,t,L,1:flatpoints);
                linsub = polyval(polyfit(1:flatpoints,lineonly',2),1:flatpoints);
                filtscan(c,t,L,1:flatpoints) = lineonly - linsub';
            end
        end
    end
end

clear('rawscan');

filtscan=filtscan(:,:,:,1:size(filtscan,4)-1);

% Tip moves in opposite direction in case of retrace. Must invert the 
% X axis of the retrace data

for c=1:numcants
    temp = zeros(numlines,size(filtscan,4));
    temp(:,:)=filtscan(c,2,:,:);
    temp = fliplr(temp);
    filtscan(c,2,:,:)=temp;
end