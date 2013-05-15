module("conf.logic_func", package.seeall)
local config = require "conf.config"
local common = require "conf.common"
local cjson = require "cjson"

--------------------------------funcs for check_url
function check_url(url)
    local url = ngx.decode_base64(url)
    local host = common.get_host(url)
    if host == '' then
        ngx.exit(ngx.HTTP_BAD_REQUEST)
    end
    
    local quoted_host = ndk.set_var.set_quote_pgsql_str(host)
    
    -- first query the db, if not found, then match the gray rules
    local match, ret = url_match_db(quoted_host)
    if not match then
        match, ret = match_gray_rules(url ,host)
    end

    return cjson.encode(ret)
end

function url_match_db(quoted_host)
    local match = false
    local ret = {['type']=config.GRAY_HOST, ['reason']=''}

    --First query the white list, then query the black list
    local host_types = {config.WHITE_HOST, config.BLACK_HOST}
    for i, host_type in pairs(host_types) do
        local match, reason = query_host_list(host_type, quoted_host)
	if match then
            ret['type'] = check_type
	    ret['reason'] = reason
            break
	end
    end

    return match, ret
end

function match_gray_rules(url, host)
    local match = false
    local ret = {['type']=config.GRAY_HOST, ['reason']=''}
    
    for _, gray_rule in pairs(gray_rules) do
	for name, value in pairs(gray_rule) do
	    if name == config.URL_RULE then
                local m = ngx.re.match(url, value, 'jo')
                if m then
                    match = true
                    ret['type'] = config.BLACK_HOST
	    	    ret['reason'] = gray_rule['name']
                    break
                end
            elseif name == config.HOST_RULE then
                local m = ngx.re.match(host, value, 'jo')
                if m then
                    match = true
                    ret['type'] = config.BLACK_HOST
	    	    ret['reason'] = gray_rule['name']
                    break
                end
            elseif name == config.DOMAIN_RULE then
                local m = ngx.re.match(host, value, 'jo')
                if m then
                    match = true
                    ret['type'] = config.BLACK_HOST
	    	    ret['reason'] = gray_rule['name']
                    break
                end
            end
        end
    end
    return match, ret
end

function query_host_list(host_type, quoted_host)
    local match = false
    local reason = ''

    local sql = [[SELECT reason FROM ]].. host_type .. [[_host WHERE host = ]] .. quoted_host
    local state, res = common.query_from_db(sql)
    if state == true and table.getn(res) > 0 then
        match = true
        reason = res[1]['reason']
    end
    return match, reason
end

-- to prevent use of casual module global variables
getmetatable(conf.logic_func).__newindex = function (table, key, val)
    error('attempt to write to undeclared variable "' .. key .. '": '
            .. debug.traceback())
end
