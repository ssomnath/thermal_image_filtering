function [filt,filt2] = myfilter(data,av,polyorder)
    
    filt = zeros(floor(length(data)/av),1);
    j=1;
    for i=1+(av/2):av:length(data)
        temp=sum(data((i-(av/2)):min(length(data),i+(av/2))));
        filt(j)=temp/av;
        j=j+1;
    end
    
    % Discard last data point:
    filt = filt(1:(length(filt)-1));
    figure(1);
    subplot(2,1,1);
    linsub = polyval(polyfit((1:length(filt))',filt,polyorder),(1:length(filt)))';
    plot(1:length(filt),filt,'b'); hold on;
    plot(1:length(linsub),linsub,'r');
    xlabel('data point'); ylabel('Vsense (V)');title('Filtered data');
    
    filt2 = filt-linsub;
    subplot(2,1,2);
    plot(1:length(filt2),filt2);
    xlabel('data point'); ylabel('\DeltaVsense (V)');title('Filtered & polynomial subtracted data');
    
end