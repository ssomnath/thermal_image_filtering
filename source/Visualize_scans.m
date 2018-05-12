%% Use this script to visualize cleaned scans NOT raw data

%% File read:
clear; clc;

numcants = 30;%input('How many cantilevers? ');
   
[FileName,PathName,FilterIndex] = uigetfile({'*.txt'},'Select C1_T data file');

headerlines=0;

sprintf('Path: %s\n',PathName);

disp('Loading C1_T.txt')
fileToRead1 = strcat(PathName,'C1_T.txt');
data = importdata(fileToRead1, '\t', headerlines);
scansize = size(data);
scan = zeros(numcants,2,scansize(1),scansize(2));
scan(1,1,:,:) = data; 

disp('Loading C1_R.txt')
fileToRead1 = strcat(PathName,'C1_R.txt');
scan(1,2,:,:) = importdata(fileToRead1, '\t', headerlines);


for cant=2:numcants
    disp(strcat('Loading C',num2str(cant),'_T.txt'))
    fileToRead1 = strcat(PathName,'C',num2str(cant),'_T.txt');
    scan(cant,1,:,:) = importdata(fileToRead1, '\t', headerlines);
    
    
    disp(strcat('Loading C',num2str(cant),'_R.txt'))
    fileToRead1 = strcat(PathName,'C',num2str(cant),'_R.txt');
    scan(cant,2,:,:) = importdata(fileToRead1, '\t', headerlines);
    
end

%disp('Loaded data to memory')
fprintf('Loaded files from: %s to memory\n',PathName);
fprintf('Scans have %d X %d pixels\n',size(scan,3),size(scan,4));

clear('FileName','FilterIndex','fileToRead1','vars','headerlines','data','scansize','cant','ans');

numrows = 0; numcols = 0;
if(numcants <= 30)
    numrows = 6; numcols = 5;
elseif(numcants <=  5)
    numrows = 3; numcols = 2;
end

%% Scan Visualization

%figure(37);

b=zeros(size(scan,3),size(scan,4));

for cant=1:size(scan,1)
    
    b(:,:)=scan(cant,1,:,:);
        
    figure;%subplot(numrows,numcols,cant); 
    imagesc(b);title(sprintf('C %dT',cant));

end
disp('~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~');
clear('cant','b','displayImageType');

%% Shift columns:

b=zeros(size(scan,3),size(scan,4));
c=zeros(size(scan,3),size(scan,4));
Cindex1 = input('Cantilever A index (1-30)\n');
b(:,:)=scan(Cindex1,1,:,:);
Cindex2 = input('Cantilever B index (1-30)\n');
c(:,:)=scan(Cindex2,1,:,:);
keepShifting = 1;
splitIndex1 = -1; splitIndex2 = -1;
figure(1);
while(keepShifting)
	temp1 = input('Enter column at which to split first cant (-1 to stop)\n');
    temp2 = input('Enter column at which to split last cant (-1 to stop)\n');
	if(temp1 == -1 || temp1 > size(scan,4) || temp2 == -1 || temp2 > size(scan,4))
       keepShifting = 0;
       if(splitIndex1 > 1 && splitIndex2 > 1)
            figure(37);
            disp('Shifting all cantilevers.....');
            
            for cant=1:size(scan,1)
    
                splitIndex = splitIndex1 + (cant - Cindex1)*(splitIndex2 - splitIndex1)/(Cindex2- Cindex1);
                splitIndex = max(1,floor(splitIndex));

                b(:,:)=scan(cant,1,:,:);
                b = [b(:,splitIndex:size(scan,4)),b(:,1:splitIndex-1)];
                scan(cant,1,:,:) = b;

                subplot(numrows,numcols,cant); 
                imagesc(b);
                title(sprintf('C %dT',cant));

                b(:,:)=scan(cant,2,:,:);
                b = [b(:,splitIndex:size(scan,4)),b(:,1:splitIndex-1)];
                scan(cant,2,:,:) = b;

            end
           disp('Shift complete');
       end
    else
        
        subplot(2,2,1);
        imagesc(b); title(sprintf('C %dT',Cindex1));
        subplot(2,2,2);
        splitIndex1 = temp1;
        imagesc([b(:,splitIndex1:size(scan,4)),b(:,1:splitIndex1-1)]);
        subplot(2,2,3);
        imagesc(c);title(sprintf('C %dT',Cindex2));
        subplot(2,2,4);
        splitIndex2 = temp2;
        imagesc([c(:,splitIndex2:size(scan,4)),c(:,1:splitIndex2-1)]);
    end
end

clear('ans','c','keepShifting','temp1','temp2','Cindex1','Cindex2','ans','b','cant','splitIndex','splitIndex1','splitIndex2');


%% Flip matrices for Frame up:

isFrameUp = input('Invert the scan (Up Down)? Non zero - yes\n');
if(isFrameUp)
    disp('Inverting scan for Frame up...');
    for cant=1:size(scan,1)
        b=zeros(size(scan,3),size(scan,4));c=zeros(size(scan,3),size(scan,4));
        b(:,:)=scan(cant,1,:,:);c(:,:)=scan(cant,2,:,:);
        scan(cant,1,:,:) = flipud(b);
        scan(cant,2,:,:) = flipud(c);
    end
    clear('b','c','cant');
end

clear('isFrameUp');

%% Rewrite corrected scans back to HDD:

writeToFile = input('Write corrected files to disk? Non zero - yes\n');

if(writeToFile)
    
    disp('Writing output files....')
    basename = strcat(PathName,'Cleaned');
    mkdir(basename)
        
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