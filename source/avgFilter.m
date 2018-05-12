function scan = avgFilter(scan,av,iters)

av=floor(av);
if((av/2) ~= floor(av/2))
    av=av+1;
    sprintf('Averaging size increased to %d',av);
end
iters=floor(iters);
if(iters<0 || iters>10)
    iters=1;
end

numcants=size(scan,1);
numlines=size(scan,3);
numpts=size(scan,4);

for c=1:numcants
    for t=1:2
        for L=1:numlines 
            for j=1:iters
                for i=1:numpts
                    st=max(i-(av/2),1);
                    fin=min(i+(av/2),numpts);
                    scan(c,t,L,i)=sum(scan(c,t,L,st:fin))/(1+fin-st);
                end
            end
        end
    end
end

end