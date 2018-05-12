%% Truncating to 10 um x 1.25 um and THEN decimating:
% This assumes b and c are correctly initialized

figure(9);
subplot(2,1,1);
plot(1:size(b,2),b(1,:));
subplot(2,1,2);
plot(1:size(c,2),c(1,:));

%% Specify truncation limits for scan:

st = 4340; en = 6389;
b2 = b(:,st:en);
st = 5290; en = 7339;
c2 = c(:,st:en);

%% Double check selection:
% if this doesn't look good - go back to filt scan -> it still has the full
% data
figure(10);
subplot(2,1,1);
plot(1:size(b2,2),b2(1,:));
subplot(2,1,2);
plot(1:size(c2,2),c2(1,:));

%% Go ahead with truncation:

rawscan(1,1,:,:) = b2(:,:);
rawscan(1,2,:,:) = c2(:,:);
fprintf('Scan truncated to %d lines x %d pixels',size(rawscan,3),size(rawscan,4))