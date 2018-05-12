function filtscan = polyFlattenX(filtscan,c,polynom)

numlines=size(filtscan,3);
numpts=size(filtscan,4);

lineonly = zeros(numpts,1);

% X Flatten
for t=1:2
    for L=1:numlines            
        lineonly(:) = filtscan(c,t,L,:);
        linsub = polyval(polynom,1:numpts);
        filtscan(c,t,L,:) = lineonly - linsub';
    end
end