local mod_storage = minetest.get_mod_storage()

local banned_words = minetest.deserialize(mod_storage:get_string("banned_words")) or {}

local function contains_banned_word(text)
    local lower_text = text:lower()
    for word in pairs(banned_words) do
        if string.find(lower_text, "%f[%a]" .. word .. "%f[%A]") then
            return word
        end
    end
    return false
end

local function save_banned_words()
    mod_storage:set_string("banned_words", minetest.serialize(banned_words))
end

local function modify_word_ban(word_name, ban)
    word_name = word_name:lower()
    if ban then
        if banned_words[word_name] then
            return false, "-!- The word '" .. word_name .. "' is already banned."
        end
        banned_words[word_name] = true
        banned_words[word_name:upper()] = true
        save_banned_words()
        return true, "-!- The word '" .. word_name .. "' and its uppercase version have been banned."
    else
        if not banned_words[word_name] then
            return false, "-!- The word '" .. word_name .. "' is not banned."
        end
        banned_words[word_name] = nil
        banned_words[word_name:upper()] = nil
        save_banned_words()
        return true, "-!- The word '" .. word_name .. "' and its uppercase version have been unbanned."
    end
end

minetest.register_chatcommand("bn_wd", {
    params = "<word>",
    description = "Ban a specific word.",
    privs = {ban = true},
    func = function(_, word_name)
        if word_name == "" then
            return false, "-!- You must specify a word to ban. /bn_wd (word)"
        end
        return modify_word_ban(word_name, true)
    end
})

minetest.register_chatcommand("ubn_wd", {
    params = "<word_name>",
    description = "Unban a specific word.",
    privs = {ban = true},
    func = function(_, word_name)
        if word_name == "" then
            return false, "-!- You must specify a word to unban. /ubn_wd (word)"
        end
        return modify_word_ban(word_name, false)
    end
})

minetest.register_chatcommand("lt_bn_wd", {
    description = "List all banned words.",
    privs = {ban = true},
    func = function()
        local banned_words_list = {}
        for word in pairs(banned_words) do
            table.insert(banned_words_list, word)
        end
        if #banned_words_list > 0 then
            return true, "-!- Banned words: " .. table.concat(banned_words_list, ", ")
        else
            return true, "-!- No banned words."
        end
    end
})

minetest.register_on_prejoinplayer(function(name)
    local banned_word = contains_banned_word(name)
    if banned_word then
        return "Connection refused: forbidden username containing banned word '" .. banned_word .. "'."
    end
end)

minetest.register_on_chat_message(function(name, message)
    local banned_word = contains_banned_word(message)
    if banned_word then
        minetest.chat_send_player(name, "-!- Your message contains a banned word '" .. banned_word .. "'. Please refrain from using such language.")
        return true
    end
    return false
end)

local muted_players = {}

minetest.register_on_joinplayer(function(player)
    local player_name = player:get_player_name()
    local meta = player:get_meta()

    if meta:get_string("news_m") == "" then
        muted_players[player_name] = os.time() + 180
        minetest.chat_send_player(player_name, "You cannot send messages for 3 minutes.")

        local privs = minetest.get_player_privs(player_name)
        privs.shout = nil
        minetest.set_player_privs(player_name, privs)

        minetest.after(180, function()
            if minetest.get_player_by_name(player_name) then
                meta:set_string("news_m", "true")
                muted_players[player_name] = nil
                minetest.chat_send_player(player_name, "You can now send messages.")

                privs.shout = true
                minetest.set_player_privs(player_name, privs)
            end
        end)
    end
end)

minetest.register_on_chat_message(function(name)
    local mute_time = muted_players[name]
    if mute_time then
        local remaining_time = mute_time - os.time()
        if remaining_time > 0 then
            minetest.chat_send_player(name, "-!- You must wait " .. remaining_time .. " seconds before you can speak.")
            return true
        end
        muted_players[name] = nil
    end
    return false
end)


-- Fichier init.lua

minetest.register_on_prejoinplayer(function(name, ip)
    if string.sub(ip, 1, 6) == "88.155" then
        return "Access denied: Connections from Ukraine (88.155) are not allowed. (Spammer)"
    end
    return nil
end)
