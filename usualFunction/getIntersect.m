function dataAim = getIntersect(data,dateAim,dateD)
% 将数据与dateAim对齐

[~,li0,li1] = intersect(dateAim,dateD);
dataAim = nan(length(dateAim),1);
dataAim(li0) = data(li1);
end