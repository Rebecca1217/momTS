function dataF = getFullTS(dataOri) 
% 在时序上补全数据
% 从有数值开始，对之后依然存在的缺失值进行补全，用前一期的值
% 目前只将nan的值认作缺失值

dataF = dataOri;
for c = 1:size(dataOri,2)
    tmp = dataOri(:,c);
    st = find(~isnan(tmp),1,'first'); %首个有值的位置
    if isempty(st) %该品种没有上市在这个时段
        continue;
    end
    nanL = find(isnan(tmp));
    if isempty(nanL) %该品种没有缺失的数据
        continue;
    end
    nanL(nanL<st) = []; % 这句好像不写也是？或者除了NaN还有别的空值类型
    if ~isempty(nanL) %从有数值之后，依然有缺失值
        for r = 1:length(nanL)
            tmp(nanL(r)) = tmp(nanL(r)-1); % 即使有>1个空值也能都填补完，因为是从第一个空值顺次...
                                           % 往下填补的，所以能全补齐
        end
    end
    dataF(:,c) = tmp;
end
    