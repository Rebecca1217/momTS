function dataF = getFullTS(dataOri) 
% ��ʱ���ϲ�ȫ����
% ������ֵ��ʼ����֮����Ȼ���ڵ�ȱʧֵ���в�ȫ����ǰһ�ڵ�ֵ
% Ŀǰֻ��nan��ֵ����ȱʧֵ

dataF = dataOri;
for c = 1:size(dataOri,2)
    tmp = dataOri(:,c);
    st = find(~isnan(tmp),1,'first'); %�׸���ֵ��λ��
    if isempty(st) %��Ʒ��û�����������ʱ��
        continue;
    end
    nanL = find(isnan(tmp));
    if isempty(nanL) %��Ʒ��û��ȱʧ������
        continue;
    end
    nanL(nanL<st) = [];
    if ~isempty(nanL) %������ֵ֮����Ȼ��ȱʧֵ
        for r = 1:length(nanL)
            tmp(nanL(r)) = tmp(nanL(r)-1);
        end
    end
    dataF(:,c) = tmp;
end
    