function factorData = sFactor_TA_PR_002(data,para)
% ===========������������������==================
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
FType = para.FType;

% �������
dataBasicO = getBasicData(fut_variety,FPath,dateBasic,'Open');
dataBasicC = getBasicData(fut_variety,FPath,dateBasic,'Close');
dataBasicH = getBasicData(fut_variety,FPath,dateBasic,'High');
dataBasicL = getBasicData(fut_variety,FPath,dateBasic,'Low');

flagYinYang = dataBasicC-dataBasicO; %�ж����߻�������
flagDifH = [nan(1,size(dataBasicH,2));diff(dataBasicH)]; %��߼۵Ĳ�ֵ
flagDifL = [nan(1,size(dataBasicL,2));diff(dataBasicL)]; %��ͼ۵Ĳ�ֵ

factorData = zeros(size(dataBasicO)); %����1������-1������Ϊ0
for t = 3:length(dateBasic)
    if FType==1
        % ��
        CL1 = flagYinYang(t-2,:)<0 & flagYinYang(t-1,:)>0 & flagYinYang(t,:)>0; %������
        CL2 = flagDifL(t,:)>0 & dataBasicO(t-2,:)-dataBasicC(t,:)<0; %
        CL3 = (flagDifH(t-1,:)>=0 & flagDifL(t-1,:)<=0) | (flagDifH(t-1,:)<=0 & flagDifL(t-1,:)>=0); %Kbar(lag1)��Kbar(lag2)Ϊ��û��̬
        % ��
        CS1 = flagYinYang(t-2,:)>0 & flagYinYang(t-1,:)<0 & flagYinYang(t,:)<0; %������
        CS2 = flagDifH(t,:)<0 & dataBasicO(t-2,:)-dataBasicC(t,:)>0;
        CS3 = dataBasicO(t-1,:)-dataBasicO(t-2,:)>0 & dataBasicO(t,:)-dataBasicC(t-1,:)>0; %�߿�
        %
        flagS = CS1 & CS2 & CS3;
        flagL = CL1 & CL2 & CL3;
        factorData(t,flagL==1) = 1;
        factorData(t,flagS==1) = -1;
    else
        % ��
        CL1 = flagYinYang(t-2,:)<0 & flagYinYang(t-1,:)>0 & flagYinYang(t,:)>0; %������
        CL2 = flagDifH(t,:)>0 & dataBasicC(t-1,:)-dataBasicL(t-2,:)>0;
        % ��
        CS1 = flagYinYang(t-2,:)>0 & flagYinYang(t-1,:)>0 & flagYinYang(t,:)<0; %������
        CS2 = flagDifL(t,:)<0 & dataBasicC(t-1,:)-dataBasicH(t-2,:)>0;
             %
        flagS = CS1 & CS2;
        flagL = CL1 & CL2;
        factorData(t,flagL==1) = 1;
        factorData(t,flagS==1) = -1;
    end
end
    
factorData = getNeedData(factorData,dateBasic,dateST,dateED); %�����������нس���Ҫ������



    
    
