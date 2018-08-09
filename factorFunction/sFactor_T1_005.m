function factorData = sFactor_T1_005(data,para)
% ==================���в���������================
% Type1:��ȥwin������rtn<0
% Type2:�ҹ�ȥwin��rtn<0
% --------------�������-------------------
% para.dateST;para.dateED;para.type;para.win1;para.win2
% win1:���������ʵ�win��win2:���㲨���ʵ�win
% --------------�������------------------
% factorData:col1-���ڣ��������
% --------------�������------------------
% type1:����ȱʧ����һ�룬��Ϊnan���������е����棬ֵΪ-inf
% type2:��������������������㴰���ڳ��ȣ���Ϊnan
% ������ʱ����������ݲ�ȫ

dateBasic = data.Date;

type = para.type;
win = para.win2;
dateST = para.dateST;
dateED = para.dateED;

% ����������-���ö�������
paraR.win = para.win1; 
paraR.PType = para.PType;
paraR.dateST = dateBasic(1);
paraR.dateED = dateBasic(end);
rtnData = sFactor_T1_001(data,paraR); %��������������
rtnData = rtnData(:,2:end); %ȥ����������

factorData = nan(size(rtnData));
if type==1 %��ȥwin����rtn<0
    % �Ȱ����ڣ��ٰ�Ʒ��
    for d = win:length(dateBasic)
        tmp = rtnData(d-win+1:d,:);
        vltmp = nan(1,size(tmp,2));
        for c = 1:size(tmp,2)
            if sum(isnan(tmp(:,c)))>=win/2 %ȱʧ�����ݳ����˴����ڳ��ȵ�һ��
                vltmp(c) = nan;
            else
                if sum(tmp(:,c)<0)==0 %�������ڵ������Ϊ��
                    vltmp(c) = -inf;
                else
                    vltmp(c) = std(tmp(tmp(:,c)<0,c));
                end
            end
        end
        factorData(d,:) = vltmp;
    end
elseif type==2 %�ҹ�ȥwin��rtn<0
    % ��Ʒ��
    for c = 1:size(rtnData,2)
        tmp = rtnData(:,c);
        vltmp = nan(size(tmp));
        li = find(tmp<0); %������������
        if length(li)<win %������ĸ����ﲻ�������ڳ���
            vltmp(:) = nan;
        else
            for d = li(win):length(tmp)
                litmp = li(find(li<=d,10,'last'));
                vltmp(d) = std(tmp(litmp));
            end
        end
        factorData(:,c) = vltmp;
    end
end
            
% factorData = getFullTS(factorData); %ʱ�����油ȫ����
factorData = getNeedData(factorData,dateBasic,dateST,dateED); %�����������нس���Ҫ������