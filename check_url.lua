local logic_func = require "conf.logic_func"

ngx.req.read_body()
local args = ngx.req.get_post_args()

if not args.url then
    ngx.exit(ngx.HTTP_BAD_REQUEST)
end

local ret = logic_func.check_url(args.url)
ngx.say(ret)
