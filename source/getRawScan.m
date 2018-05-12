function rawscan = getRawScan(data)

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
if(length(fst) == 0 || length(lst) == 0)
    disp('Trigger not acquired correctly')
    return;
end
if(fst==0 || lst==0)
    disp('Trigger channel error');
    return;
end
trig = trig(fst:lst);
data = abs(data(fst:lst,1:numcants));



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

if(numlines==0)
    disp('No line triggers found in trigger channel! Aborting');
    return;
end

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
% There are some lines with 0 pixels or considerably less pixels than other
% lines. What do we do in this case?

if min(maxpixel) < (median(maxpixel)-100) % This is rare
    disp('Anomalie in getRawScan: one or more of the rows have too few pixels');
    %return;
    
    % Ideally let the user know about this
    % One solution is to delete these lines
    % since it is unlikely that they have any good information
    % I only hope that these occurances are NOT in the middle of a scan
    
    %[val,pos] = min(maxpixel);
    
    % rawscan(cant, trace/retrace, line, pixel)
    %rawscan = rawscan(:,:,(1:pos-1),:);
    % Resolve this issue
    
    %rawscan = rawscan(:,:,size(rawscan,3)-63:size(rawscan,3),:);
    %maxpixel = maxpixel(1:min(64,length(maxpixel)));
    
    % Common occurance: Only last line is too short:   
    if (maxpixel(length(maxpixel)) < (median(maxpixel)-100)) && (maxpixel(length(maxpixel)-1)+30 >= median(maxpixel))
        disp('          Attempted solution type 1');
        maxpixel = maxpixel(1:length(maxpixel)-1);
    end
    %maxpixel = maxpixel(1:length(maxpixel)-15);
    %rawscan = rawscan(:,:,1:size(rawscan,3)-15,:);
    
end
rawscan = rawscan(:,:,:,1:min(maxpixel));

clear('data','trig','maxpixel')
clear('fst','lst','i','j','lineindex','pixelindex','prev','rawcols','rawrows','rising','temp');
end