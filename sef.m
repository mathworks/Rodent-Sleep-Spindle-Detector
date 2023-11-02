function sf=sef(signal,cutoff_freq,FS)
% sf=sef(a,totplim,sr)
% spectral edge frequency
% sr = sampling frequency
% totplim = vector with cutoff frequencies for total power spectrum
if nargin == 2
    FS = 200;
elseif nargin == 1
    FS = 200;
    cutoff_freq = [0.5 40];
end
if isempty(FS), FS=100; end
if isempty(cutoff_freq), cutoff_freq=[0.5 40]; end
[aha1, aha2]=periodogram(signal,[],[],FS);
if isempty((find(isnan(aha1)))) && aha1(end)~=0
    d=length(aha1(aha2<cutoff_freq(1)));
    op=find(cumsum(aha1(aha2>=cutoff_freq(1)))>0.5*sum(aha1(aha2>=cutoff_freq(1)&aha2<=cutoff_freq(2))));
    sf=aha2(op(1)+d);
else
    sf=NaN;
end