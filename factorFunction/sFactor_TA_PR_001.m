function factorData = sFactor_TA_PR_001(data,para)
% ===========����������������==================
% ȱʧ��������ʱ���ϵĲ�ȫ
% -----------�������---------------
% data.fut_variety;data.FPath;data.Date-����ȱʧֵΪnan���ñ�����Ȩ���ݣ�ԭʼ������
% para.dateST;para.dateED-��Ҫ������
% -----------�������---------------
% factorData:col1-���ڣ��������

dateBasic = data.Date;
fut_variety = data.fut_variety;
FPath = data.FPath;

dateST = para.dateST;
dateED = para.dateED;

% �������
dataBasicO = getBasicData(fut_variety,FPath,dateBasic,'Open');
dataBasicC = getBasicData(fut_variety,FPath,dateBasic,'Close');
dataBasicH = getBasicData(fut_variety,FPath,dateBasic,'High');
dataBasicL = getBasicData(fut_variety,FPath,dateBasic,'Low');

flagYinYang = dataBasicC-dataBasicO; %�ж����߻�������
flagDifC = [nan(1,size(dataBasicC,2));diff(dataBasicC)]; %���̼۵Ĳ�ֵ
flagGap = [nan(1,size(dataBasicC,2));dataBasicO(2:end,:)-dataBasicC(1:end-1,:)]; %��������

factorData = zeros(size(dataBasicO)); %����1������-1������Ϊ0
for t = 3:length(dateBasic)
    % ������
    Yin3 = flagYinYang(t,:)<0 & flagYinYang(t-1,:)<0 & flagYinYang(t-2,:)<0;
%     Yin3 = (flagYinYang(t,:)<0) + (flagYinYang(t-1,:)<0) + (flagYinYang(t-2,:)<0)>=2;
    DifCDn = flagDifC(t,:)<0 & flagDifC(t-1,:)<0;
    GapDn = flagGap(t,:)>=0 | flagGap(t-1,:)>=0; %�������������������տ���
    % ������
    Yang3 = flagYinYang(t,:)>0 & flagYinYang(t-1,:)>0 & flagYinYang(t-2,:)>0;
%     Yang3 = (flagYinYang(t,:)>0) + (flagYinYang(t-1,:)>0) + (flagYinYang(t-2,:)>0)>=2;
    DifCUp = flagDifC(t,:)>0 & flagDifC(t-1,:)>0;
    GapUp = flagGap(t,:)<=0 |flagGap(t-1,:)<=0; %�������������������տ���
    
    %
    flagS = Yin3 & DifCDn ;%& GapDn;
    flagL = Yang3 & DifCUp ;%;& GapUp;
    factorData(t,flagL==1) = 1;
    factorData(t,flagS==1) = -1;
end
    
factorData = getNeedData(factorData,dateBasic,dateST,dateED); %�����������нس���Ҫ������



    
    
