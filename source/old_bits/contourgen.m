function scan = contourgen(data,stline1,eoline1)
%contourf([1,2,3;2,2,1;3,1,1]);
% Need to reshape the array to a 2D matrix depending on the provided
% instrucitons (guess)
% Allowing user to discard a few lines in the beginning
data = data(stline1:length(data));
numpts = eoline1-stline1;
numlines = floor(length(data)/numpts);
data = data(1:numpts*numlines);
scan = reshape(data,numpts,numlines);
%contourf(scan);
figure(10);
surf(scan');
end