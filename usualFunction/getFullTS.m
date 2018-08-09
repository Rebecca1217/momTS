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
    nanL(nanL<st) = [];
    if ~isempty(nanL) %从有数值之后，依然有缺失值
        for r = 1:length(nanL)
            tmp(nanL(r)) = tmp(nanL(r)-1);
        end
    end
    dataF(:,c) = tmp;
end
    