function dataAim = getIntersect(data,dateAim,dateD)
% ��������dateAim����

[~,li0,li1] = intersect(dateAim,dateD);
dataAim = nan(length(dateAim),1);
dataAim(li0) = data(li1);
end