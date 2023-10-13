
%% files for histograms
file_histo_y = 'output/histo_y.txt';
file_histo_cr = 'output/histo_cr.txt';
file_histo_cb = 'output/histo_cb.txt';

%% read files
histo_y = readmatrix(file_histo_y);
histo_cr = readmatrix(file_histo_cr);
histo_cb = readmatrix(file_histo_cb);

%% plot histograms
figure(1)
subplot(3,1,1), bar(histo_y(:,1),histo_y(:,3:-1:2));
title('Y-Channel')
legend('Your Design','Reference')
grid on
subplot(3,1,2), bar(histo_cr(:,1),histo_cr(:,3:-1:2));
title('Cr-Channel')
legend('Your Design','Reference')
grid on
subplot(3,1,3), bar(histo_cb(:,1),histo_cb(:,3:-1:2));
title('Cb-Channel')
legend('Your Design','Reference')
grid on

figure(2)
subplot(3,1,1), bar(histo_y(:,1),histo_y(:,3),'r');
title('Y-Channel (Your Design)')
grid on
subplot(3,1,2), bar(histo_cr(:,1),histo_cr(:,3),'r');
title('Cr-Channel (Your Design)')
grid on
subplot(3,1,3), bar(histo_cb(:,1),histo_cb(:,3),'r');
title('Cb-Channel (Your Design)')
grid on

figure(3)
subplot(3,1,1), bar(histo_y(:,1),histo_y(:,2));
title('Y-Channel (Reference)')
grid on
subplot(3,1,2), bar(histo_cr(:,1),histo_cr(:,2));
title('Cr-Channel (Reference)')
grid on
subplot(3,1,3), bar(histo_cb(:,1),histo_cb(:,2));
title('Cb-Channel (Reference)')
grid on
