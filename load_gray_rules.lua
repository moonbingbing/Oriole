local common = require "conf.common"
local config = require "conf.config"

function load_gray_rules(gary_rule_file)
    gray_rules = {}
    local file = io.open(gary_rule_file)
    if not file then  -- file not exists
	return false, gray_rules
    end

    local data = file:read("*a") --read all content
    file:close()
    
    for _, rule_info in pairs(common.split(data, '%-%-%-%-')) do
        local rule = {}
	for _, rule_section in pairs(common.split(rule_info, '\n')) do
	    rule_section = common.strip(rule_section)
	    if rule_section ~= '' and rule_section[1] ~= '#' and #rule_section > 5 then
                local delimiter_index = string.find(rule_section, '=')
		if delimiter_index then
                    local key = common.strip( string.sub(rule_section,1,delimiter_index-1) )
                    local value = common.strip( string.sub(rule_section,delimiter_index+1) )
                    if key == config.DOMAIN_RULE then
			value = value .. '$'
                    end
                    value = string.gsub(value, [[%.]], [[\%.]])
                    rule[key] = value
		end
	    end
        end
	table.insert(gray_rules, rule)
    end
	
    return true, gray_rules
end

_,gray_rules = load_gray_rules('/opt/openresty/nginx/conf/gray.rule')
