function scan = avg2DFilter(scan,av,iters)

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
        for j=1:iters
           for L=1:numlines  
                for i=1:numpts
                    stX=max(i-(av/2),1);
                    finX=min(i+(av/2),numpts);
                    stY=max(L-(av/2),1);
                    finY=min(L+(av/2),numlines);
                    tot=0;
                    for p=stY:finY
                        tot=tot+sum(scan(c,t,p,stX:finX));
                    end
                    scan(c,t,L,i)=tot/((1+finX-stX)*(1+finY-stY));
                end
            end
        end
    end
end

end