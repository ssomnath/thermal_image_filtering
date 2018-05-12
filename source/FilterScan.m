function filtscan = FilterScan(rawscan,av)

    numcants=size(rawscan,1);
    numlines=size(rawscan,3);
    numpix=size(rawscan,4);

    filtscan = zeros(numcants, 2, numlines, floor(numpix/av));
            
    rawpix = 1;
    filtpix = 1;

    while rawpix <= numpix
        st = rawpix;
        en = min(rawpix +av - 1, numpix);

        for c=1:numcants
            for t=1:2   
                for L=1:numlines  
                    temp=sum(rawscan(c,t,L,st:en));
                    filtscan(c,t,L,filtpix) = temp/(en-st+1);
                end
            end
        end

        rawpix = rawpix + av;
        filtpix = filtpix + 1;
    end
            
    clear('rawscan');

    filtscan=filtscan(:,:,:,1:filtpix-1);

    % Tip moves in opposite direction in case of retrace. Must invert the 
    % X axis of the retrace data

    for c=1:numcants
        temp = zeros(numlines,size(filtscan,4));
        temp(:,:)=filtscan(c,2,:,:);
        temp = fliplr(temp);
        filtscan(c,2,:,:)=temp;
    end
end