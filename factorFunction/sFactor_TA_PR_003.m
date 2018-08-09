function factorData = sFactor_TA_PR_003(data,para)
% ===========�ϵ�������==================
% ȱʧ��������ʱ���ϵĲ�ȫ
% -----------�������---------------
% data.fut_variety;data.FPath;data.Date-����ȱʧֵΪnan���ñ�����Ȩ���ݣ�ԭʼ������
% para.dateST;para.dateED-��Ҫ������
% -----------�������---------------
% factorData:col1-���ڣ��������

dateBasic = data.Date;
fut_variety = data.fut_variety;
FPath = data.FPath;
winBF = 10;
winAF = 2;



dateST = para.dateST;
dateED = para.dateED;
FType = para.FType;
TypeOri = para.TypeOri;

% �������
dataBasicO = getBasicData(fut_variety,FPath,dateBasic,'Open');
dataBasicC = getBasicData(fut_variety,FPath,dateBasic,'Close');
dataBasicH = getBasicData(fut_variety,FPath,dateBasic,'High');
dataBasicL = getBasicData(fut_variety,FPath,dateBasic,'Low');

flagYinYang = dataBasicC-dataBasicO; %�ж����߻�������
flagGaoDi = dataBasicH-dataBasicL; %��߼�-��ͼ�
maxP = zeros(size(dataBasicC)); %���ռ��еĸ߼�
minP = zeros(size(dataBasicC)); %���ռ��еĵͼ�
for l = 1:size(dataBasicC,2)
    maxP(:,l) = max([dataBasicC(:,l),dataBasicO(:,l)],[],2);
    minP(:,l) = min([dataBasicC(:,l),dataBasicO(:,l)],[],2);
end
flagUp = dataBasicH-maxP; %�����ߵĳ���
flagDn = minP-dataBasicL; %�����ߵĳ���
flagZD = [nan(winBF,size(dataBasicC,2));dataBasicC(winBF+1:end,:)-dataBasicC(1:end-winBF,:)]; %�۸���ǵ�
flagZD_AF = [nan(winAF,size(dataBasicC,2));dataBasicC(winAF+1:end,:)-dataBasicC(1:end-winAF,:)]; %�۸���ǵ�,��̬����֮��

% K����̬
if strcmp(TypeOri,'Ori')
    % ���ߡ������ߺܶ��ҳ���С��ʵ��ĳ��ȡ�ʵ��С
    LenUp = flagUp./flagGaoDi<0.2 & flagUp<abs(flagYinYang); %�����߳���
    LenShi = abs(flagYinYang)./flagGaoDi<0.25; %ʵ��С
    flagKbar = flagYinYang>0 & LenUp & LenShi;
elseif strcmp(TypeOri,'ChgO1_1')
    % �����ߺܶ��ҳ���С��ʵ��ĳ��ȡ�ʵ��С
    LenUp = flagUp./flagGaoDi<0.2 & flagUp<abs(flagYinYang); %�����߳���
    LenShi = abs(flagYinYang)./flagGaoDi<0.25; %ʵ��С
    flagKbar = LenUp & LenShi;
elseif strcmp(TypeOri,'Ori2')
    % ���ߡ������ߺܶ��ҳ���С��ʵ��ĳ��ȡ�ʵ��С
    LenDn = flagDn./flagGaoDi<0.2 & flagDn<abs(flagYinYang); %�����߳���
    LenShi = abs(flagYinYang)./flagGaoDi<0.25; %ʵ��С
    flagKbar = flagYinYang<0 & LenDn & LenShi;
elseif strcmp(TypeOri,'ChgO2_1')
    % �����ߺܶ��ҳ���С��ʵ��ĳ��ȡ�ʵ��С
    LenDn = flagDn./flagGaoDi<0.2 & flagDn<abs(flagYinYang); %�����߳���
    LenShi = abs(flagYinYang)./flagGaoDi<0.25; %ʵ��С
    flagKbar = LenDn & LenShi;
end
   
  
factorData = zeros(size(dataBasicO)); %����1������-1������Ϊ0

if FType==1 %��������k����̬
    flagL = flagKbar;
    factorData(flagL==1) = 1;
elseif FType==2 %K����̬+ǰ�ڵ�����
    flagS = flagZD>0 & flagKbar; %ǰ�������ҳ��ָ���̬
    flagL = flagZD<0 & flagKbar; %ǰ���µ��ҳ��ָ���̬
    factorData(flagL==1) = 1;
    factorData(flagS==1) = -1;
elseif FType==3 %K����̬+ǰ�ڵ�����+���ڵ�����
    flagL1 = flagZD<0 & flagKbar; %ǰ���µ��ҳ��ָ���̬
    flagS1 = flagZD>0 & flagKbar; %ǰ�������ҳ��ָ���̬
    flagS1_shift = [nan(winAF+1,size(flagS1,2));flagS1(1:end-winAF-1,:)];
    flagL1_shift = [nan(winAF+1,size(flagL1,2));flagL1(1:end-winAF-1,:)];
    flagS = flagS1_shift==1 & flagZD_AF<0; %ǰ�������ҳ��ָ���̬,�Һ����µ�
    flagL = flagL1_shift==1 & flagZD_AF>0; %ǰ���µ��ҳ��ָ���̬,�Һ�������
    factorData(flagL==1) = 1;
    factorData(flagS==1) = -1;
end

    
factorData = getNeedData(factorData,dateBasic,dateST,dateED); %�����������нس���Ҫ������



    
    
