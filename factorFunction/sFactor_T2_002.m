function factorData = sFactor_T2_002(data,para)
% ===========���޽ṹ�䶯����==================
% ���º�Լ�ۼ�����-Զ�º�Լ�ۼ�����
% ȱʧ��������ʱ���ϵĲ�ȫ
% -----------�������---------------
% data.Date;data.NPath;data.NAddPath;data.FPath;data.FAddPath;data.fut_variety
% Path����Լ����·������fut��һ��
% fut_variety:������׺
% para.win;para.PType;para.dateST;para.dateED-��Ҫ������
% -----------�������---------------
% factorData:col1-���ڣ��������
% ��δ��Ȩ����ȥ�����ȷֱ������º�Զ�º�Լÿ�յ������ʣ�Ȼ���ټ����ۼ�����

dateBasic = data.Date;
NPath = data.NPath; %���º�Լ·��
NAddPath = data.NAddPath;
FPath = data.FPath; %Զ�º�Լ·��
FAddPath = data.FAddPath;
fut_variety = data.fut_variety;

win = para.win;
PType = para.PType;
dateST = para.dateST;
dateED = para.dateED;

% ���Ʒ�ּ���ÿ�յ�������-���º�Զ��
rtnN = getRtn(NPath,NAddPath,dateBasic,fut_variety,PType);
rtnF = getRtn(FPath,FAddPath,dateBasic,fut_variety,PType);

% �����ۼ�������֮��
factorData = nan(length(dateBasic),length(fut_variety));
for d = win:length(dateBasic)
    cumRtnN = cumprod(1+rtnN(d-win+1:d,:));
    cumRtnF = cumprod(1+rtnF(d-win+1:d,:));
    factorData(d,:) = cumRtnN(end,:)-cumRtnF(end,:);
end

factorData = getFullTS(factorData); %ʱ�����油ȫ����
factorData = getNeedData(factorData,dateBasic,dateST,dateED); %�����������нس���Ҫ������

end
   

function rtn = getRtn(ZPath,AddPath,dateBasic,fut_variety,PType)
% ����ÿ�յ�������

rtn = nan(length(dateBasic),length(fut_variety));
for i_fut = 1:length(fut_variety)
    fut = fut_variety{i_fut};
    % �����Լ����
    load([ZPath,'\',fut,'.mat'])
    str = ['priceF = futureData.',PType,';'];
    eval(str)
    date = futureData.Date;
    priceF = getIntersect(priceF,dateBasic,date);
    priceF = getFullTS(priceF);
    try
        % �����Լ��������
        load([AddPath,'\',fut,'.mat'])
        dateA = futureData.Date;
        str = ['priceA = futureData.',PType,';'];
        eval(str)
    catch %��Ʒ��û������
        rtn(:,i_fut) = [nan;tick2ret(priceF)];
    end
    % ��������
    tmp = [nan;tick2ret(priceF)];
    % �Ի��µ����ݽ��е���
    [~,chgLBF,liA] = intersect(dateBasic,dateA); %���µ�ǰһ��������
    if isempty(chgLBF)
        rtn(:,i_fut) = tmp;
        continue;
    else
        if chgLBF(end)==length(dateBasic) %�����ݽ�ֹ���ڵĺ�һ�컻���£�����һ���ڵ�ǰ���ô���
            chgLBF(end) = [];
            liA(find(dateA==dateBasic(end),1)) = [];
        end
  
        tmp(chgLBF+1) = priceF(chgLBF+1)./priceA(liA)-1;
        rtn(:,i_fut) = tmp;
    end   
end
end


function dataAim = getIntersect(data,dateAim,dateD)
% ��������dateAim����

[~,li0,li1] = intersect(dateAim,dateD);
dataAim = nan(length(dateAim),1);
dataAim(li0) = data(li1);
end

function dnum = getDateNum(cont,dateBasic,ltdInfo)
% �����Լ���뵽���յ���Ȼ������

info = zeros(length(dateBasic),3);
info(:,1:2) = [cont,dateBasic];
contUni = unique(cont);
for c = 1:length(contUni)
    info(cont==contUni(c),3) = ltdInfo(ltdInfo(:,1)==contUni(c),3);
end
dnum = datenum(num2str(info(:,3)),'yyyymmdd')-datenum(num2str(info(:,2)),'yyyymmdd');

end

    
    
