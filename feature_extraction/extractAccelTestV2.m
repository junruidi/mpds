% @Author: Andong Zhan
% @Date:   2018-02-18 13:40:58
% @Last Modified by:   Andong Zhan
% @Last Modified time: 2018-02-18 14:03:00
% (c) 2018 Max Little. If you use this code, please cite:
% Andong Zhan, et al. "High Frequency Remote Monitoring of Parkinson's Disease
%  via Smartphone: Platform Overview and Medication Response Detection."
% arXiv preprint arXiv:1601.00960 (2016).

function [header, feature] = extractAccelTestV2( data )
% Useage:
% [header, feature] = extractAccelTestV2( data )
% Inputs
%    data       - input signal: a matrix where each row is a accleration
%                 sample. The columns are time, x, y, z. time is when the
%                 sample recorded and <x, y, z> are the three dimension
%                 acceleration.
% Outputs:
%    header     - the names of the acceleration features
%    feature    - the feature matrix
%
[nr, nc] = size(data);
header = {};
% remove 1st and last quartor
X = zeros(nr, nc+4);
X(:,1:4) = data;

% normalize x,y,z
m = abs(mean(X(:,2:4)));
[B,I] = sort(m,'descend');
x = X(:,I(1)+1); % x is the gravity direction
y = X(:,I(2)+1); % y is the walking direction
z = X(:,I(3)+1);
X(:,2) = x;
X(:,3) = y;
X(:,4) = z;

% remove gravity component
X(:,2:4) = rmgravity(X(:,2:4), 'mean');

X(:,5) = sqrt(sum(data(:,2:4) .* data(:,2:4), 2));
[a,e,r] = cart2sph(data(:,2),data(:,3),data(:,4));
X(:,6) = a;
X(:,7) = e;
X(:,8) = r;
T = X(:,1);
A = X(:,2:8);
% statistical features
stats_h = {'mean', 'std', 'q1', 'q3', 'iqr', 'median', 'mode', 'range', ...
    's', 'k', 'mse','En', 'zcr', 'dfc', 'dfc_amp', 'meanTKEO', 'ar1', 'dfa'};
axes_h = {'x','y','z','acc','a','e','r'};
NA = numel(axes_h);
N = numel(stats_h);
for i = 1:NA
    for j = 1:N
        name = strcat(axes_h{i}, '_', stats_h{j});
        header{(i-1)*N + j} = name;
    end
end
% dominant frequency component
%F = 1:10;
minF = 0.5;
maxF = 20;
[pxx, f] = plomb(A,T,maxF);
ind = f > minF;
f = f(ind);
pxx = pxx(ind, :);


[amp, maxi] = max(pxx);
dfc = f(maxi)';
Q1 = prctile(A,25);
Q3 = prctile(A,75);
stats_f = [
    mean(A);
    std(A);
    Q1;
    Q3;
    Q3 - Q1;
    median(A);
    mode(A);
    max(A) - min(A);
    skewness(A);
    kurtosis(A);
    mean(A.*A);
    entropy(A(:,1)) entropy(A(:,2)) entropy(A(:,3)) entropy(A(:,4))...
    entropy(A(:,5)) entropy(A(:,6)) entropy(A(:,7));
    ZCR(normalize(A(:,1))) ZCR(normalize(A(:,2))) ZCR(normalize(A(:,3))) ZCR(normalize(A(:,4)))...
    ZCR(normalize(A(:,5))) ZCR(normalize(A(:,6))) ZCR(normalize(A(:,7)));
    dfc;
    amp;
    FeatureMeanTKEO(A(:,1)) FeatureMeanTKEO(A(:,2))...
    FeatureMeanTKEO(A(:,3)) FeatureMeanTKEO(A(:,4))...
    FeatureMeanTKEO(A(:,5)) FeatureMeanTKEO(A(:,6))...
    FeatureMeanTKEO(A(:,7));
    FeatureAR1(A(:,1)) FeatureAR1(A(:,2)) FeatureAR1(A(:,3)) FeatureAR1(A(:,4)) ...
    FeatureAR1(A(:,5)) FeatureAR1(A(:,6)) FeatureAR1(A(:,7));
    fastdfa(A(:,1)) fastdfa(A(:,2)) fastdfa(A(:,3)) fastdfa(A(:,4))...
    fastdfa(A(:,5)) fastdfa(A(:,6)) fastdfa(A(:,7));
];
stats_f = reshape(stats_f, [1,N*7]);
% cross features on x,y,z and acc axis
cross_h = {'xcorr','mi','xEn'};
corr = zeros(1,9);
MI = zeros(1,9);
xEn = zeros(1,9);
idx = 1;
nh = numel(header);
for i = 1:3
    for j = i+1:4
        for k = 1:numel(cross_h)
            header{nh + (idx-1)*numel(cross_h) + k} ...
                = strcat(axes_h{i}, '_',axes_h{j}, '_', cross_h{k});
        end
        r = corrcoef(A(:,i),A(:,j));
        corr(1,idx) = r(1,2);
        MI(1,idx) = mi(A(:,i),A(:,j));
        xEn(1,idx) = entropy(A(:,i)) + ...
            relativeEntropy(round(A(:,i).*10000),round(A(:,j).*10000));
        idx = idx + 1;
    end
end
% cross features on a,e,r
nh = numel(header);
nidx = idx;
for i = 5:6
    for j = i+1:7
        for k = 1:numel(cross_h)
            header{nh + (idx-nidx)*numel(cross_h) + k} ...
                = strcat(axes_h{i}, '_',axes_h{j}, '_', cross_h{k});
        end
        r = corrcoef(A(:,i),A(:,j));
        corr(1,idx) = r(1,2);
        MI(1,idx) = mi(A(:,i),A(:,j));
        xEn(1,idx) = entropy(A(:,i)) + ...
            relativeEntropy(round(A(:,i).*10000),round(A(:,j).*10000));
        idx = idx + 1;
    end
end


cross_f = [corr;MI;xEn];
cross_f = reshape(cross_f, 1, 9*numel(cross_h));
feature = [stats_f cross_f];


end