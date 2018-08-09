function [HoldingInfo,HoldingInfoTM] = futAllocationFactor(wgtType,Cap,paraAlc,totaldate)
% ���ݲ�ͬȨ�����÷�ʽȷ������Ʒ�ֵĳֲ�������Ȩ��
% Ҫ���Ǹ��ڵ������أ�����������ȷ��Ȩ�غ�����
% ���԰���ڷ���������Ҫ���Ʒ�ַ���Ȩ��
% t�յĿ��������ͼ�¼��t��

% ����
capital = Cap.Capital; %������ֵ
% ͨ��·��
tdDPath = paraAlc.tdDPath;
usualPath = paraAlc.usualPath;
futLiquidPath = paraAlc.futLiquidPath;
futSectorPath = paraAlc.futSectorPath;

% ����Ӧ��Ʒ��
IndustryChoice = paraAlc.IndustryChoice;
load(futSectorPath,IndustryChoice)
str = ['fut_variety = ',IndustryChoice,';'];
eval(str) 

% ��Լ����
load([usualPath,'\cont_multi.mat'])
[~,~,li1] = intersect(fut_variety,cont_multi(:,1),'stable'); %˳������
contMulti = cont_multi(li1,:);
contMulti = cell2mat(contMulti(:,2));
% 
if strcmpi(wgtType,'eqATR')
    ATRpath = paraAlc.ATRpath;
    budget = paraAlc.budget;
    % ����ATR����
    ATRData = nan(length(totaldate),length(fut_variety)+1);
    ATRData(:,1) = totaldate;
    for i_fut = 1:length(fut_variety)
        fut = fut_variety{i_fut};
        % ��������
        load([ATRpath,'\',fut,'.mat'])
        dateATR = ATRindex(:,1);
        dataATR = ATRindex(:,end);
        % ���ݶ���
        [~,li0,li1] = intersect(dateATR,totaldate);
        ATRData(li1,i_fut+1) = dataATR(li0)*contMulti(i_fut); %ATR�����ú�Լ����������
    end
    % ����ֱֲ���
    % 0.���������Զ�Ʒ�ֽ���ɸѡ
    % 1.���շ�����ƽȷ��ÿ��Ʒ�ֵ�����
    % 2.�����������ÿ��Ʒ�ֵĿ�����ֵ
    % 3.���ݿɿ��ֵĳ�ʼ��ֵ�����ÿ��Ʒ��ʵ�ʿɿ�����ֵ
    % 4.��ʵ�ʿ�����ֵ�����ÿ��Ʒ�ֵĿ�������
    % 0.������
    for d = 1:length(totaldate)
        load([futLiquidPath,'\',num2str(totaldate(d)),'.mat'])
        [~,li0] = setdiff(fut_variety,liquidityInfo);
        ATRData(d,li0+1) = nan;
    end
    % 1.����
    HoldingHandsOri = round(budget./ATRData(:,2:end)); %����
    % 2.������������ɿ�����ֵ
    % ����������Լ�۸�����-����������ʵռ��
    mainData = nan(length(totaldate),length(fut_variety)+1);
    mainData(:,1) = totaldate;
    for i_fut = 1:length(fut_variety)
        fut = fut_variety{i_fut};
        % ��������
        load([tdDPath,'\',fut,'.mat']) %��ʵ��Լ����
        clData = futureData.Close;
        dateMain = futureData.Date;
        % ���ݶ���
        [~,li0,li1] = intersect(dateMain,totaldate);
        mainData(li1,i_fut+1) = clData(li0)*contMulti(i_fut); %���̼������ú�Լ����������
    end
    for d = 1:length(totaldate)
        load([futLiquidPath,'\',num2str(totaldate(d)),'.mat'])
        [~,li0] = setdiff(fut_variety,liquidInfo);
        mainData(d,li0+1) = nan;
    end
    totalSize = HoldingHandsOri.*mainData(:,2:end);
    totalSizeDly = nansum(totalSize,2);
    HoldingWgtOri = bsxfun(@times,totalSize,repmat(1./totalSizeDly,1,size(totalSize,2)));
    % 3.��ֵ����
    HoldingSize = HoldingWgtOri*capital; %Ԥ�ȷ���Ŀ�����ֵ
    % 4.��������
    HoldingHands = round(HoldingSize./mainData(:,2:end));
    realSize = HoldingHands.*mainData(:,2:end);
    realSizeDly = nansum(realSize,2);
    HoldingWgt = bsxfun(@times,realSize,repmat(1./realSizeDly,1,size(realSize,2)));
    %
    HoldingInfo.Hands = [totaldate,[nan(1,length(fut_variety));HoldingHands(1:end-1,:)]];
    HoldingInfo.Size = [totaldate,[nan(1,length(fut_variety));realSize(1:end-1,:)]]; %ʵ�ʿ�����ֵ������ǰһ������̼ۼ��㣩
    HoldingInfo.NomSize = [totaldate,[nan(1,length(fut_variety));HoldingSize(1:end-1,:)]]; %����Ŀ�����ֵ
    HoldingInfo.Weight = [totaldate,[nan(1,length(fut_variety));HoldingWgt(1:end-1,:)]]; %ʵ�ʵ�Ȩ��ռ��
    HoldingInfo.NomWeight = [totaldate,[nan(1,length(fut_variety));HoldingWgtOri(1:end-1,:)]]; %�����Ȩ��
elseif strcmpi(wgtType,'eqSize')
    % ����������Լ����
    mainData = nan(length(totaldate),length(fut_variety)+1);
    mainData(:,1) = totaldate;
    for i_fut = 1:length(fut_variety)
        fut = fut_variety{i_fut};
        % ��������
        load([tdDPath,'\',fut,'.mat']) %��ʵ��Լ����
        clData = futureData.Close;
        dateMain = futureData.Date;
        % ���ݶ���
        [~,li0,li1] = intersect(dateMain,totaldate);
        mainData(li1,i_fut+1) = clData(li0)*contMulti(i_fut); %���̼������ú�Լ����������
    end
    for d = 1:length(totaldate)
        load([futLiquidPath,'\',num2str(totaldate(d)),'.mat'])
        [~,li0] = setdiff(fut_variety,liquidityInfo);
        mainData(d,li0+1) = nan;
    end
    % ��������
    ListNum = sum(~isnan(mainData(:,2:end)),2); %���㵱�����е�Ʒ����
    HoldingSize = repmat(capital./ListNum,1,length(fut_variety));
    HoldingSize(isnan(mainData(:,2:end))) = nan;
    HoldingHands = round(HoldingSize./mainData(:,2:end));
    realSize = HoldingHands.*mainData(:,2:end);
    realSizeDly = nansum(realSize,2);
    HoldingWgt = bsxfun(@times,realSize,repmat(1./realSizeDly,1,size(realSize,2)));
    HoldingWgtOri = repmat(1./ListNum,1,size(realSize,2));
    HoldingWgtOri(isnan(mainData(:,2:end))) = nan;
    %
    HoldingInfo.Hands = [totaldate,[nan(1,length(fut_variety));HoldingHands(1:end-1,:)]];
    HoldingInfo.Size = [totaldate,[nan(1,length(fut_variety));realSize(1:end-1,:)]]; %ʵ�ʿ�����ֵ
    HoldingInfo.NomSize = [totaldate,[nan(1,length(fut_variety));HoldingSize(1:end-1,:)]]; %����Ŀ�����ֵ
    HoldingInfo.Weight = [totaldate,[nan(1,length(fut_variety));HoldingWgt(1:end-1,:)]];
    HoldingInfo.NomWeight = [totaldate,[nan(1,length(fut_variety));HoldingWgtOri(1:end-1,:)]]; %�����Ȩ��

elseif strcmpi(wgtType,'fixSize') %����Ʒ�ֵĿ�����ֵ�ǹ̶���
    % ����������Լ����
    mainData = nan(length(totaldate),length(fut_variety)+1);
    mainData(:,1) = totaldate;
    for i_fut = 1:length(fut_variety)
        fut = fut_variety{i_fut};
        % ��������
        load([tdDPath,'\',fut,'.mat']) %��ʵ��Լ����
        clData = futureData.Close;
        dateMain = futureData.Date;
        % ���ݶ���
        [~,li0,li1] = intersect(dateMain,totaldate);
        mainData(li1,i_fut+1) = clData(li0)*contMulti(i_fut); %���̼������ú�Լ����������
    end
    % ��������
    HoldingSize = repmat(capital,length(mainData),length(fut_variety));
    HoldingSize(isnan(mainData(:,2:end))) = nan;
    HoldingHands = round(HoldingSize./mainData(:,2:end));
    realSize = HoldingHands.*mainData(:,2:end);
    realSizeDly = nansum(realSize,2);
    HoldingWgt = bsxfun(@times,realSize,repmat(1./realSizeDly,1,size(realSize,2)));
    %
    HoldingInfo.Hands = [totaldate,[nan(1,length(fut_variety));HoldingHands(1:end-1,:)]];
    HoldingInfo.Size = [totaldate,[nan(1,length(fut_variety));realSize(1:end-1,:)]]; %ʵ�ʿ�����ֵ
    HoldingInfo.NomSize = [totaldate,[nan(1,length(fut_variety));HoldingSize(1:end-1,:)]]; %����Ŀ�����ֵ
    HoldingInfo.Weight = [totaldate,[nan(1,length(fut_variety));HoldingWgt(1:end-1,:)]]; %ʵ�ʵ�Ȩ��ռ��
end

HoldingInfoTM.Hands = HoldingInfo.Hands(end,:);
HoldingInfoTM.Size = HoldingInfo.Size(end,:);
HoldingInfoTM.NomSize = HoldingInfo.NomSize(end,:);
HoldingInfoTM.Weight = HoldingInfo.Weight(end,:);
HoldingInfoTM.NomWeight = HoldingInfo.NomWeight(end,:);

HoldingInfo.Hands(end,:) = [];
HoldingInfo.Size(end,:) = [];
HoldingInfo.NomSize(end,:) = [];
HoldingInfo.Weight(end,:) = [];
HoldingInfo.NomWeight(end,:) = [];

HoldingInfo.fut_variety = fut_variety;
