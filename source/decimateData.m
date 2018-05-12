function filtscan = decimateData(data,av)

   filtscan = zeros(floor(size(data,1)/av),size(data,2));

   k=1;j=1;
    while k <= size(data,1)
        st = k;
        en = min(k+av-1,size(data,1));
        for col =1:size(data,2)   
            temp=sum(data(st:en,col));
            filtscan(j,col)=temp/(en-st+1);
        end
        k=k+av;
        j=j+1;
    end

    filtscan=filtscan(1:j-1,:);
end