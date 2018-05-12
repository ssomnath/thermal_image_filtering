function [avsize, ptsToAdd, NiceRes] = OptimalFiltering(rawpix, lowRes, highRes, showPlots)

%rawpix = 19921;
%lowRes = 1024;
%highRes = 1984;

if(rawpix >= lowRes && rawpix <= highRes)
    avsize = 1;
    if(floor(rawpix/32) == round(rawpix/32)) % Remove pts 
        NiceRes = floor(rawpix/32)*32;
    else % Add pts to get to multiple of 32
        NiceRes = ceil(rawpix/32)*32;
    end
    ptsToAdd = NiceRes-rawpix; 
    return;
elseif(ceil(rawpix/highRes) > floor(rawpix/lowRes))
    avsize = [2:-1:1];   
elseif(ceil(rawpix/highRes) == floor(rawpix/lowRes))
    avsize = [round(rawpix/lowRes):-1:round(rawpix/highRes)];
else
    avsize = [floor(rawpix/lowRes):-1:ceil(rawpix/highRes)];
end
ptsToAdd = zeros(size(avsize));
NiceRes = zeros(size(avsize));
for i=1:length(avsize)
    filtpts = floor(rawpix/avsize(i))+1;
    if(floor(filtpts/32) == round(filtpts/32)) % Remove pts 
        NiceRes(i) = floor(filtpts/32)*32;
    else % Add pts to get to multiple of 32
        NiceRes(i) = ceil(filtpts/32)*32;
    end
    NiceRes(i) = max(lowRes,NiceRes(i));
    NiceRes(i) = min(highRes,NiceRes(i));
    ptsToAdd(i) = NiceRes(i)-filtpts; 
end

if(showPlots)
	figure; 
	subplot(3,1,1);plot(NiceRes,ptsToAdd,'o-');xlabel('Asylum Pixels');ylabel('Points to Add');
	subplot(3,1,2);plot(NiceRes,avsize,'o-');xlabel('Asylum Pixels');ylabel('Points to Average');
    subplot(3,1,3);plot(avsize,ptsToAdd,'o-');xlabel('Points to Average');ylabel('Points to Add');
end
