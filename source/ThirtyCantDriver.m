clear all; close all; clc
log = '';
fileindex =1;
headerlines=0;
noMoreFiles = 0;
rest = zeros(1,31);
masterscan = 0;
avgSamps = 0;
triggerDebug=0;
cd 'C:\Users\somnath2\Dropbox\Matlab\ThermalImageFiltering'

%% Load first files in sequence 
% no import because we need the folder path to access remaining files
[FileName1,PathName1,FilterIndex] = uigetfile({'*.txt'},'Select the first data file in the sequence');
basename = FileName1(1:max(strfind(FileName1,'_First.txt')-1));
FileName2 = strcat(basename,'_Second.txt');
clear('FilterIndex');
        
%%
tic
while(~noMoreFiles) 
    
    disp('----------------------------------------------------------')
    
    % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Load file
    
    fileToRead1 = strcat(PathName1,FileName1);
    log = strcat(log,sprintf('Opening %s',FileName1),'\n');
    fprintf('Opening %s .....\n',fileToRead1)
    data1 = importdata(fileToRead1, '\t', headerlines);
    disp('Loaded data to memory')
    log = strcat(log,'Loaded data to memory\n');
    
    fileToRead1 = strcat(PathName1,FileName2);
    log = strcat(log,sprintf('Opening %s',FileName2),'\n');
    fprintf('Opening %s .....\n',fileToRead1)
    data2 = importdata(fileToRead1, '\t', headerlines);
    disp('Loaded data to memory')
    log = strcat(log,'Loaded data to memory\n');
    
    % For checking / debugging purposes: see trigger channel
    % figure(41); plot(data1(:,16));

    % Assumes that trigger going to slot3/ai15
    if(size(data1,1) > size(data2,1))
        data1 = data1(1:size(data2,1),:);
        fprintf('%s has %d more samples than %s. Discarding\n',FileName1, size(data1,1)-size(data2,1),FileName2)
        log = strcat(log,sprintf('%s has %d more samples than %s. Discarding',FileName1, size(data1,1)-size(data2,1),FileName2),'\n');
    elseif(size(data1,1) < size(data2,1))  
        data2 = data2(1:size(data1,1),:);
        fprintf('%s has %d more samples than %s. Discarding\n',FileName2, size(data2,1)-size(data1,1),FileName1)
        log = strcat(log,sprintf('%s has %d more samples than %s. Discarding',FileName2, size(data2,1)-size(data1,1),FileName1),'\n');
    end
    data = [data1,data2];
    
    clear('fileToRead1','vars','newData1','data1','data2');
        
    % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Raw data to Raw Scan

    disp('Parsing raw data...');
    
    if(triggerDebug)
        if(fileindex > 1)
            figure(37); subplot(1,3,1);plot(rest(:,31)); title(strcat('Rest: Data loop: #',num2str(fileindex)));
        end
        figure(37); subplot(1,3,2);plot(data(:,31)); title(strcat('Data: Data loop: #',num2str(fileindex)));
    end
    
    data = [rest; data];
    
    if(triggerDebug)
        figure(37); subplot(1,3,3); plot(data(:,31)); title(strcat('Everythng: Data loop: #',num2str(fileindex)));

        goahead = input('Hit Enter to continue');
        clear('goahead');
    end  
    
    
    
    [rawscan,rest] = getRawScan30chunks(data);
    
    if(size(rawscan,1) == 1  || size(rest,2) == 1)
        % Unless there is some other error, there simply wasn't enough data
        % for even a single set of lines (trace & retrace)
        % Set rest = data and append the next file.
        rest = data;
        disp('Insufficient data to reogranize to scan. Loading next file(s) in sequence.');
        log = strcat(log,'Insufficient data to reogranize to scan. Loading next file(s) in sequence.\n');
    else
        fprintf('Raw Scan generated with %d lines x %d pixels\n',size(rawscan,3),size(rawscan,4))
        log = strcat(log,sprintf('Raw Scan generated with %d lines x %d pixels',size(rawscan,3),size(rawscan,4)),'\n');
        %figure; plot(rest(:,31)); title(strcat('Rest loop #',num2str(fileindex)));
        clear('data','rest2');

        % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Decimation Scan Filtering
        %
        % Number of scan points (in igor ibw files) has to be a multiple of 32.
        % Choose the sampling rate wisely
        % Maximum number of pixels that can safely be generated is 1984
        
        
        while(avgSamps == 0)
            pointsToAdd = 0;
            [avsize, ptsToAdd, NiceRes] = OptimalFiltering(size(rawscan,4), 1024, 1984, 1);
            avgSamps=8;%input('Number of raw samples to be averaged? Use the shown plots\n');
            
            if(avgSamps <= avsize(1) && avgSamps >= avsize(length(avsize)))
                for i=1:length(avsize)
                    if(avsize(i) == avgSamps)
                       pointsToAdd = ptsToAdd(i);
                       fprintf('------------------- Need to add %d points\n',ptsToAdd(i))
                       break;
                    end
                end
            else
                avgSamps = 0;
                fprintf('\tInvalid entry, pick an integer between %d and %d using the graphs\n',avsize(length(avsize)),avsize(1));
            end
            clear('avsize','ptsToAdd','NiceRes','i');
            close all;
        end
        
       
        disp('Decimating / Filtering raw scan data....');
        scan = FilterScan(rawscan,avgSamps);
        fprintf('Scan filtered to %d lines x %d pixels\n',size(scan,3),size(scan,4))
        log = strcat(log,sprintf('Scan filtered to %d lines x %d pixels',size(scan,3),size(scan,4)),'\n');
        clear('rawscan');
       
        % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Add to parent scan:
        
        fprintf('MasterScan before adding new scan: %d cant x %d lines x %d pixels\n',size(masterscan,1),size(masterscan,3),size(masterscan,4))
        log = strcat(log,sprintf('MasterScan before adding new scan: %d cant x %d lines x %d pixels\n',size(masterscan,1),size(masterscan,3),size(masterscan,4)),'\n');

        if(size(masterscan,1) < 2)
            masterscan = scan;
        else
            if(size(masterscan,4) <= size(scan,4))
                % Truncate scan
                scan = scan(:,:,:,1:size(masterscan,4));
            else
                % Truncate masterscan
                masterscan = masterscan(:,:,:,1:size(scan,4));
            end
            % Add scan to masterscan
            masterscan(:,:,size(masterscan,3)+1:size(masterscan,3)+size(scan,3),:) = scan;
        end
    end
    
    fprintf('MasterScan after adding new scan: %d cant x %d lines x %d pixels\n',size(masterscan,1),size(masterscan,3),size(masterscan,4))
    log = strcat(log,sprintf('MasterScan after adding new scan: %d cant x %d lines x %d pixels\n',size(masterscan,1),size(masterscan,3),size(masterscan,4)),'\n');

    clear('scan');
    
    % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Decide on the next filenames
    
    suffix = num2str(fileindex);
    switch length(suffix)
        case 1
            suffix = strcat('000',suffix);
        case 2
            suffix = strcat('00',suffix);
        case 3
            suffix = strcat('0',suffix);
    end
    fileindex = fileindex+1;
    
    FileName1 = strcat(basename,'_First','_',suffix,'.txt');
    FileName2 = strcat(basename,'_Second','_',suffix,'.txt');
    
    % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Check for existence of files
    
    if(exist(strcat(PathName1,'\',FileName1),'file') && exist(strcat(PathName1,'\',FileName2),'file'))
        noMoreFiles = 0;
    else
        noMoreFiles = 1;
        disp('Finished reading all raw files.');
        toc
        log = strcat(log,'Finished reading all raw files.\n');
    end
end

clear('FileName1','FileName2','fileindex','headerlines','noMoreFiles','rest','suffix','triggerDebug','avgSamps');

%% Discard rows:
numlines=256;
masterscan = masterscan(:,:,1:numlines,:);
fprintf('Raw Scan truncated to %d lines x %d pixels\n',size(masterscan,3),size(masterscan,4))
log = strcat(log,sprintf('Raw Scan truncated to %d lines x %d pixels',size(masterscan,3),size(masterscan,4)),'\n');
clear('numlines');



%% Take absolute value:
takeabs = 1;

if(takeabs)
    masterscan = abs(masterscan);
    disp('Forced absolute value for all signals');
    log = strcat(log,'Forced absolute value for all signals\n');
end
clear('takeabs');

%% Flatten Scan

doFlatten=0;
if(doFlatten==1)
    tic
    % Making a backup of the filtered scan just in case.
    filtscan=masterscan;
    masterscan = flattenScan(masterscan,1,0);
    disp('Image flattened');
    log = strcat(log,'Image flattened\n');
    toc
end
clear('doFlatten');


%% Additional Filtering (can be done in Igor):

filtersize=0;
filteriterations=1;
if(filteriterations > 0 && filteriterations < 3 && filtersize > 0)
    disp('2D Average-filtering scan. This can take a few minutes...');
    masterscan = avg2DFilter(masterscan,filtersize,filteriterations);
    fprintf('Completed average filter of size %d over %d iterations\n',filtersize,filteriterations)
    log = strcat(log,sprintf('Completed average filter of size %d over %d iterations',filtersize,filteriterations),'\n');
end
clear('filtersize','filteriterations');

%% Convert from dVs to dVc (by inversion for voltage control):

% Need to invert
for cant=1:size(masterscan,1)
    b=zeros(size(masterscan,3),size(masterscan,4));c=zeros(size(masterscan,3),size(masterscan,4));
    b(:,:)=masterscan(cant,1,:,:);c(:,:)=masterscan(cant,2,:,:);
    m1 = max(max(b));
    m2 = max(max(c));
    masterscan(cant,1,:,:) = m1 - b;
    masterscan(cant,2,:,:) = m2 - c;
end
clear('b','c','m1','m2','cant');

disp('Converted from Vsense to Vcant by inversion');
log = strcat(log,'Converted from Vsense by inversion\n');

%% Igor IBW conform Add missing / remove excess pixels:
ibwConf = 1;%input('Reshape data to fit Asylum image files? 0-No, 1-Yes\n');

if(ibwConf)
    if(pointsToAdd > 0)
        masterscan = addPixels(masterscan, pointsToAdd);
    elseif(pointsToAdd < 0)
        masterscan = removePixels(masterscan, pointsToAdd);
    end
    fprintf('Added %d pixels to bring up to %d pixels\n',pointsToAdd,size(masterscan,4))
    log = strcat(log,sprintf('Added %d pixels to bring up to %d pixels',pointsToAdd,size(masterscan,4)),'\n');
end
clear('ibwConf','pointsToAdd');

%% Scan Visualization

displayImageType=input('Plot type? 0- 3D or non-zero: Contour\n');
displayImageFormat=input('Plot type? 0- 5 plots or non-zero: single plot\n');

pix = size(masterscan); pix = pix(3:4);
b=zeros(size(masterscan,3),size(masterscan,4));

if(displayImageFormat)
    
    
    for cant=1:size(masterscan,1)
        
        b(:,:)=masterscan(cant,1,:,:);
        subplot(6,5,cant); 
        if(displayImageType)
        	imagesc(b);
        else
            surf(b);
        end
        title(sprintf('C %dT',cant));
        
    end
    
else
    for i=1:5
        figure;
        for j=1:6
            cant = (i-1)*6 + j;
            b(:,:)=masterscan(cant,1,:,:);
            subplot(2,3,j);
            if(displayImageType)
                imagesc(b);
            else
                surf(b);
            end
            title(sprintf('C %d ',cant));
        end
    end
end

disp('~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~');
clear('cant','displayImageType','displayImageFormat','pix','b','i','j');
toc

%% Shift columns:

b=zeros(size(masterscan,3),size(masterscan,4));
c=zeros(size(masterscan,3),size(masterscan,4));
Cindex1 = input('Cantilever A index (1-30)\n');
b(:,:)=masterscan(Cindex1,1,:,:);
Cindex2 = input('Cantilever B index (1-30)\n');
c(:,:)=masterscan(Cindex2,1,:,:);
keepShifting = 1;
splitIndex1 = -1; splitIndex2 = -1;
figure;
while(keepShifting)
	temp1 = input('Enter column at which to split first cant (-1 to stop)\n');
    temp2 = input('Enter column at which to split last cant (-1 to stop)\n');
	if(temp1 == -1 || temp1 > size(masterscan,4) || temp2 == -1 || temp2 > size(masterscan,4))
       keepShifting = 0;
       if(splitIndex1 > 1 && splitIndex2 > 1)
            figure(37);
            disp('Shifting all cantilevers.....');
            
            for cant=1:size(masterscan,1)
    
                splitIndex = splitIndex1 + (cant - Cindex1)*(splitIndex2 - splitIndex1)/(Cindex2- Cindex1);
                splitIndex = max(1,floor(splitIndex));

                b(:,:)=masterscan(cant,1,:,:);
                b = [b(:,splitIndex:size(masterscan,4)),b(:,1:splitIndex-1)];
                masterscan(cant,1,:,:) = b;

                subplot(6,5,cant); 
                imagesc(b);
                title(sprintf('C %dT',cant));

                b(:,:)=masterscan(cant,2,:,:);
                b = [b(:,splitIndex:size(masterscan,4)),b(:,1:splitIndex-1)];
                masterscan(cant,2,:,:) = b;

            end
            fprintf('Shifted all cantilevers. nParameters: Cant #%d at pix: %d and Cant #%d at pix: %d.\n',Cindex1,splitIndex1,Cindex2,splitIndex2)
            log = strcat(log,sprintf('Shifted all cantilevers. nParameters: Cant #%d at pix: %d and Cant #%d at pix: %d.',Cindex1,splitIndex1,Cindex2,splitIndex2),'\n');

       end
    else
        
        subplot(2,2,1);
        imagesc(b); title(sprintf('C %dT',Cindex1));
        subplot(2,2,2);
        splitIndex1 = temp1;
        imagesc([b(:,splitIndex1:size(masterscan,4)),b(:,1:splitIndex1-1)]);
        subplot(2,2,3);
        imagesc(c);title(sprintf('C %dT',Cindex2));
        subplot(2,2,4);
        splitIndex2 = temp2;
        imagesc([c(:,splitIndex2:size(masterscan,4)),c(:,1:splitIndex2-1)]);
    end
end

clear('ans','c','keepShifting','temp1','temp2','Cindex1','Cindex2','ans','b','cant','splitIndex','splitIndex1','splitIndex2');

%% Flip matrices for Frame up:

isFrameUp = input('Invert the scan (Up Down)? Non zero - yes\n');
if(isFrameUp)
    for cant=1:size(masterscan,1)
        b=zeros(size(masterscan,3),size(masterscan,4));c=zeros(size(masterscan,3),size(masterscan,4));
        b(:,:)=masterscan(cant,1,:,:);c(:,:)=masterscan(cant,2,:,:);
        masterscan(cant,1,:,:) = flipud(b);
        masterscan(cant,2,:,:) = flipud(c);
    end
    clear('b','c','cant');
end
disp('Inverted scan for Frame up');
log = strcat(log,'Inverted scan for Frame up\n');
clear('isFrameUp');

%% File output

writeToFile = input('Write cleaned data to disk? Non zero - yes\n');

if(writeToFile==1)
    
    disp('Writing output files....')
    basename = strcat(PathName1,basename);
    mkdir(basename)
    
    file_1 = fopen(strcat(basename,'\log.txt'),'w');
    fprintf(file_1,log);
    fclose(file_1);
    clear('file_1');
    
    if(matlabpool('size') == 0)
       matlabpool % Start parallel iterations
    end
    
    parfor cant=1:size(masterscan,1)
        b=zeros(size(masterscan,3),size(masterscan,4));c=zeros(size(masterscan,3),size(masterscan,4));
        b(:,:)=masterscan(cant,1,:,:);c(:,:)=masterscan(cant,2,:,:);

        file_1 = fopen(strcat(basename,'\C',num2str(cant),'_T.txt'),'w');

        for i=1:size(b,1)
            for j=1:size(b,2)
               fprintf(file_1,'%8.6f\t',b(i,j)); 
            end
            fprintf(file_1,'\n');
        end

        fclose(file_1);
        fprintf('   C%d_T.txt completed\n',cant)

        file_2 = fopen(strcat(basename,'\C',num2str(cant),'_R.txt'),'w');

        for i=1:size(c,1)
            for j=1:size(c,2)
               fprintf(file_2,'%8.6f\t',c(i,j)); 
            end
            fprintf(file_2,'\n');
        end

        fclose(file_2);
        fprintf('   C%d_R.txt completed\n',cant)

        %clear('file_1','file_2','i','j');
    end
    
    clear('file_1','file_2','i','j');
    fprintf('Files written to folder: %s\n',basename)
end
disp('-------------------------------------------------');
clear('cant','writeToFile','timestart','ans');
%end