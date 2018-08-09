function factorData = sFactor_T1_010(data,para)
% ===========RSI����==================
% rsi(t)=sma(max(c(t)-c(t-1),0),win,1)/sma(abs(c(t)-c(t-1)),win,1)*100
% ȱʧ��������ʱ���ϵĲ�ȫ
% -----------�������---------------
% data.FPath;data.AddPath;data.Date;data.fut_variety
% FPath:�ڻ�����·����AddPath:��������·��
% para.win;para.PType;para.dateST;para.dateED-��Ҫ������
% -----------�������---------------
% factorData:col1-���ڣ��������
% �������˻��µ�Ӱ�죬���µ��յļ۲���º�Լ����ļ۸�����ǰһ��ļ۸����

dateBasic = data.Date;
FPath = data.FPath; %������Լ����·��
AddPath = data.AddPath; %������Լ��������·��
fut_variety = data.fut_variety;

win = para.win;
PType = para.PType; %�۸�����
dateST = para.dateST;
dateED = para.dateED;

% ������۲�����
spread = nan(length(dateBasic),length(fut_variety));
for i_fut = 1:length(fut_variety)
    fut = fut_variety{i_fut};
    % ����������Լ����
    load([FPath,'\',fut,'.mat'])
    dateF = futureData.Date;
    str = ['priceF = futureData.',PType,';'];
    eval(str)
    % ���ݲ�ȫ
    priceF = getIntersect(priceF,dateBasic,dateF);
    priceF = getFullTS(priceF);
    try
        % ����������Լ��Ӧ�Ĳ�������
        load([AddPath,'\',fut,'.mat'])
        dateA = futureData.Date;
        str = ['priceA = futureData.',PType,';'];
        eval(str)
    catch %��Ʒ�ֻ�û������
        spread(:,i_fut) = [nan;diff(priceF)];
        continue;
    end
    % ��۲�
    tmp = [nan;diff(priceF)];
    % �Ի��µ�ʱ������ݽ��е���
    [~,chgLBF,liA] = intersect(dateBasic,dateA); %���µ�ǰһ��������
    if isempty(chgLBF)
        spread(:,i_fut) = tmp;
        continue;       
    else
        if chgLBF(end)==length(dateBasic) %�����ݽ�ֹ���ڵĺ�һ�컻���£�����һ���ڵ�ǰ���ô���
            chgLBF(end) = [];
            liA(find(dateA==dateBasic(end),1)) = [];
        end
        tmp(chgLBF+1) = priceF(chgLBF+1)-priceA(liA); %��������Լ��������̼�����ǰһ������̼�֮��
        spread(:,i_fut) = tmp;
    end
end
    

factorData = tech_RSI(spread,win);
factorData = getFullTS(factorData); %ʱ�����油ȫ����
factorData = getNeedData(factorData,dateBasic,dateST,dateED); %�����������нس���Ҫ������

end

function rsi = tech_RSI(data,win)
% ����RSI
% �����dataΪ�۲�����

rsi = nan(size(data));
for c = 1:size(data,2)
    dif = data(:,c); %��ֵ
    maxD = nanmax([dif,zeros(length(dif),1)],[],2); %���ֵ
    absD = abs(dif); %����ֵ
    st = find(~isnan(maxD),1,'first');
    if isempty(st)
        continue;
    else
        rsi(:,c) = sma(maxD,win,1)./sma(absD,win,1);
    end
end
end
    
    
function avg = sma(data,win,m)

avg = nan(length(data),1);
st = find(~isnan(data),1,'first');
avg(st) = data(st);
if st~=length(avg)
    for i = st+1:length(avg)
        avg(i) = avg(i-1)*(1-m/win)+data(i)*m/win;
    end
end
avg = avg*100;
end
