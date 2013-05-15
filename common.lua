module("conf.common", package.seeall)
local config = require "conf.config"
local memcached = require "resty.memcached"
local mysql = require "resty.mysql"

function get_from_memc(key)
    local memc = memcached:new()
    memc:connect(config.MEMCACHED_HOST, config.MEMCACHED_PORT)
    local res, flags, err = memc:get(key)
    memc:set_keepalive(0, 200)
    if res then
        return res
    else
        return nil
    end
end

function set_to_memc(key, value, exptime)
    if not exptime then
        exptime = 0
    end
    local memc = memcached:new()
    memc:connect(config.MEMCACHED_HOST, config.MEMCACHED_PORT)
    memc:set(key, value, exptime)
end

function query_from_db(sql)
    local db = mysql:new()
    local errinfo = ''
    db:set_timeout(10000)  -- 10s
    local ok, err, errno, sqlstate = db:connect{
        host = config.MYSQL_HOST,
        port = config.MYSQL_PORT,
        database = config.MYSQL_DATABASE,
        user = config.MYSQL_USER,
        password = config.MYSQL_PASSWORD }

    if not ok then
        errinfo = "failed to connect: ", err, ": ", errno, " ", sqlstate
        return false, errinfo
    end

    local res, err, errno, sqlstate = db:query(sql)
    if not res then
        errinfo = "bad result: ", err, ": ", errno, ": ", sqlstate, "."
        return false, errinfo
    end

    local ok, err = db:set_keepalive(0, 200)

    return true, res
end

function strip(s)
  return (string.gsub(s, "^%s*(.-)%s*$", "%1"))
end

function get_host(url)
  local host = ''
  local regex = [[//([\S]+?)/]]
  local url = string.lower(url)
  local m, err = ngx.re.match(url, regex)
  if m then
    host = m[1]
  end
  return host
end

function split(str, pat)
   local t = {}
   if str == '' or str == nil then
       return t
   end
    
   local fpat = "(.-)" .. pat
   local last_end = 1
   local s, e, cap = str:find(fpat, 1)
   while s do
      if s ~= 1 or cap ~= "" then
         table.insert(t,cap)
      end
      last_end = e+1
      s, e, cap = str:find(fpat, last_end)
   end
   if last_end <= #str then
      cap = str:sub(last_end)
      table.insert(t, cap)
   end
   return t
end

-- to prevent use of casual module global variables
getmetatable(conf.common).__newindex = function (table, key, val)
    error('attempt to write to undeclared variable "' .. key .. '": '
            .. debug.traceback())
end
