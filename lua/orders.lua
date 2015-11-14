-- KEYS[1]: cart_id
-- KEYS[2]: access_token
-- 
-- return  0: OK
-- return -1: CART_NOT_FOUND
-- return -2: NOT_AUTHORIZED_TO_ACCESS_CART
-- return -3: FOOD_OUT_OF_STOCK
-- return -4: ORDER_OUT_OF_LIMIT

local user_id = redis.call('get', 'token:'..KEYS[2]..':user')
local belong_user = redis.call('get', 'cart:'..KEYS[1]..':user')
if not belong_user then
    return -1
end

if user_id ~= belong_user then
    return -2
end

local order_exist = redis.call('get', 'user:'..user_id..':order');
if order_exist then
    return -4
end

local cart_items = redis.call('hgetall', 'cart:'..KEYS[1])
for i=1,#cart_items, 2 do
    local item_name = cart_items[i]
    local item_count = tonumber(cart_items[i+1])
    local item_stock = tonumber(redis.call('hget', 'food:stock', item_name))
    if item_count > item_stock then
        return -3
    end
end

for i=1,#cart_items, 2 do
    local item_name = cart_items[i]
    local item_count = cart_items[i+1]
    local item_stock = redis.call('hget', 'food:stock', item_name)

    redis.call('hset', 'food:stock', item_name, item_stock-item_count)
end

return 0