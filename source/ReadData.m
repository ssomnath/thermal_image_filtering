%% Initial paramters:
clear;
isFrameUp = 0;

%% File read:

headerlines=0;% Set to 4 if data was NOT derived from tdms file

log = '';
[FileName,PathName,FilterIndex] = uigetfile({'*.txt'},'Select the raw data file');

fileToRead1 = strcat(PathName,FileName);
tic
basename = fileToRead1(1:max(strfind(fileToRead1,'.txt')-1));

% Import the file
disp('----------------------------------------------------------')
fprintf('Opening %s .....\n',fileToRead1)

log = strcat(log,sprintf('Opening %s',FileName),'\n');

if(headerlines)
    newData1 = importdata(fileToRead1, '\t', headerlines);

    vars = fieldnames(newData1);
    data = newData1.(vars{1});
else
    data = importdata(fileToRead1, '\t', headerlines);
end

disp('Loaded data to memory')
log = strcat(log,'Loaded data to memory\n');

clear('FileName','PathName','FilterIndex','fileToRead1','vars','headerlines','newData1');

%% Raw data to Raw Scan
%tic

cd C:\Users\somnath2\Dropbox\Matlab\ThermalImageFiltering

disp('Parsing raw data...');
rawscan = getRawScan(data);
fprintf('Raw Scan generated with %d lines x %d pixels\n',size(rawscan,3),size(rawscan,4))
log = strcat(log,sprintf('Raw Scan generated with %d lines x %d pixels',size(rawscan,3),size(rawscan,4)),'\n');

clear('data');
toc
%% Discard rows:
numlines=64;
rawscan = rawscan(:,:,size(rawscan,3)-(numlines-1):size(rawscan,3),:);
fprintf('Raw Scan truncated to %d lines x %d pixels\n',size(rawscan,3),size(rawscan,4))
log = strcat(log,sprintf('Raw Scan truncated to %d lines x %d pixels',size(rawscan,3),size(rawscan,4)),'\n');
clear('numlines');

%% Decimation Scan Filtering
%tic
% Number of scan points (in igor ibw files) has to be a multiple of 32.
% Choose the sampling rate wisely
% Maximum number of pixels that can safely be generated is 1984
ibwConform = 0;
if(ibwConform)
    %if(size(scan,4)))
        
    %end
else
    avgSamps=10;
end  
disp('Decimating / Filtering raw scan data....');
scan = FilterScan(rawscan,avgSamps);
fprintf('Scan filtered to %d lines x %d pixels\n',size(scan,3),size(scan,4))
log = strcat(log,sprintf('Scan filtered to %d lines x %d pixels',size(scan,3),size(scan,4)),'\n');
clear('avgSamps','ibwConform');
toc

%% Take absolute value:
takeabs = 1;

if(takeabs)
    scan = abs(scan);
    disp('Forced absolute value for all signals');
    log = strcat(log,'Forced absolute value for all signals\n');
end
clear('takeabs');

%% Flatten Scan
%tic
doFlatten=1;
if(doFlatten==1)
    % Making a backup of the filtered scan just in case.
    filtscan=scan;
    scan = flattenScan(scan,1,0);
    disp('Image flattened');
    log = strcat(log,'Image flattened\n');
end
clear('doFlatten');
toc

%% Additional Filtering (can be done in Igor):
%scan = avgFilter(scan,5,2);
filtersize=0;
filteriterations=1;
if(filteriterations > 0 && filteriterations < 3 && filtersize > 0)
    disp('2D Average-filtering scan. This can take a few minutes...');
    scan = avg2DFilter(scan,filtersize,filteriterations);
    fprintf('Completed average filter of size %d over %d iterations\n',filtersize,filteriterations)
    disp('Completed average filter');
    log = strcat(log,sprintf('Completed average filter of size %d over %d iterations',filtersize,filteriterations),'\n');
end
clear('filtersize','filteriterations');

%% Convert from Vs to Vc:
Rc_setpt=6;
Rs=4.98;
scan = scan .* (Rc_setpt./Rs);
disp('Converted from Vsense to Vcant');
log = strcat(log,sprintf('Converted from Vsense to Vcant, Rs = %3.2f kOhms, Rc = %3.2f kOhms',Rs,Rc_setpt),'\n');
clear('Rc_setpt','Rs');

%% Flip matrices for Frame up:


if(isFrameUp)
    for cant=1:size(scan,1)
        b=zeros(size(scan,3),size(scan,4));c=zeros(size(scan,3),size(scan,4));
        b(:,:)=scan(cant,1,:,:);c(:,:)=scan(cant,2,:,:);
        scan(cant,1,:,:) = flipud(b);
        scan(cant,2,:,:) = flipud(c);
    end
    clear('b','c','cant');
end
disp('Inverted scan for Frame up');
log = strcat(log,'Inverted scan for Frame up\n');
clear('isFrameUp');

%% Scan Visualization

displayImageType=1;%0 = none; 1 = contour; 2 = 3D
showretrace=1;
useLimits=0;

% Z axis range
cmin = -0.07;
cmax = 0.07;

pix = size(scan); pix = pix(3:4);

for cant=1:size(scan,1)
    b=zeros(size(scan,3),size(scan,4));c=zeros(size(scan,3),size(scan,4));
    b(:,:)=scan(cant,1,:,:);c(:,:)=scan(cant,2,:,:);
        
    if(displayImageType==1)
        figure;%figure(cant);
        if(showretrace)
            subplot(2,1,2);imagesc(c);title(sprintf('Cantilever %d - Retrace',cant));colorbar;%caxis([cmin cmax])
            daspect([1/1 pix(1)*90/(pix(2)*45) 1]);% This is for a 45x90 um scan
            subplot(2,1,1);
        end

        imagesc(b);title(sprintf('Cantilever %d - Trace',cant));colorbar;%caxis([cmin cmax])
        daspect([1/1 pix(1)*90/(pix(2)*45) 1]);% This is for a 45x90 um scan
        
    elseif(displayImageType==2)
        figure(cant);
        if(showretrace)
            subplot(1,2,2);surf(c);title('Retrace');
            if(useLimits)
                axis([1 size(scan,4) 1 size(scan,3) cmin cmax]);
            end
            subplot(1,2,1);
        end
        surf(b);title('Trace'); 
        if(useLimits)
            axis([1 size(scan,4) 1 size(scan,3) cmin cmax]);
        end
    end

    clear('i','j');
end
disp('~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~');
clear('cmin','cant','cmax','displayImageType','showretrace','pix','b','c','isFrameUp','useLimits');
toc
%% File output

writeToFile=1;

if(writeToFile==1)
    
    disp('Writing output files....')
    mkdir(basename)
    
    file_1 = fopen(strcat(basename,'\log.txt'),'w');
    fprintf(file_1,log);
    fclose(file_1);
    clear('file_1');
    
    if(matlabpool('size') == 0)
        matlabpool % Start parallel iterations
    end
    
    parfor cant=1:size(scan,1)
        b=zeros(size(scan,3),size(scan,4));c=zeros(size(scan,3),size(scan,4));
        b(:,:)=scan(cant,1,:,:);c(:,:)=scan(cant,2,:,:);

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
clear('cant','writeToFile','timestart');
%end

%% Delte the source txt and tdms files
deleteSourceFiles = 1;
if(deleteSourceFiles)
    f1 = strcat(basename,'.txt');
    f2 = strcat(basename,'.tdms');
    f3 = strcat(basename,'.tdms_index');
    delete(f1,f2,f3);
    clear('f1','f2','f3');
end
clear('deleteSourceFiles');