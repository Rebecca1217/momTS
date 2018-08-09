function factorData = sFactor_T1_007(data,para)
% ===========ƫ������==================
% skewness(win)
% ȱʧ��������ʱ���ϵĲ�ȫ
% -----------�������---------------
% data.Price;data.Date-����ȱʧֵΪnan���ñ�����Ȩ���ݣ�ԭʼ������
% para.win1;para.win2;para.dateST;para.dateED-��Ҫ������
% win1:���������ʵĴ����ڲ�����win2:����ƫ�ȵĴ����ڲ���
% -----------�������---------------
% factorData:col1-���ڣ��������
% ��ʱ���ϵĲ�ȫ

dateBasic = data.Date;


win2 = para.win2;
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
for d = win2:length(dateBasic)
    tmp = rtnData(d-win2+1:d,:);
    factorData(d,:) = skewness(tmp,0);
end

factorData = getFullTS(factorData); %ʱ�����油ȫ����
factorData = getNeedData(factorData,dateBasic,dateST,dateED); %�����������нس���Ҫ������


