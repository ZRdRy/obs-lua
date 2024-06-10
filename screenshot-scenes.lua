obs = obslua
path = nil
prefix = ""
scenes = nil
scene_number = 0
scene_name = nil
next_screenshot = false
previous_scene = nil

function script_description()
	return "Takes screenshots from all scenes"
end

function go()
    if path == nil or path == "" then
        print("no path selected")
        return
    end
    if scenes == nil then
        print("start")
        scenes = obs.obs_frontend_get_scene_names()
        scene_number = -1
        next_screenshot = true
        return
    end
    if previous_scene ~= nil then
        obs.obs_source_dec_active(previous_scene)
        obs.obs_source_dec_showing(previous_scene)
        previous_scene = nil
    end
    local count = 0
    scene_name = nil
    for _, sn in ipairs(scenes) do
        if count == scene_number then
            scene_name = sn
        end
        count = count + 1 
    end
    if scene_name == nil then
        scenes = nil
        print("done")
    else
        print("take ".. scene_name)
        local source = obs.obs_get_source_by_name(scene_name)
        if source ~= nil then
            obs.obs_source_inc_showing(source)
            obs.obs_source_inc_active(source)
            obs.obs_frontend_take_source_screenshot(source)
            print("asked screenshot ".. scene_name)
            previous_scene = source
            obs.obs_source_release(source)
        else
            next_screenshot = true
        end
    end
end

function script_tick(seconds)
    if next_screenshot then
        next_screenshot = false
        scene_number = scene_number + 1
        go()
    end
end

function frontend_event(event)
     if event == obs.OBS_FRONTEND_EVENT_SCREENSHOT_TAKEN then
        local old_path = obs.obs_frontend_get_last_screenshot()
        print("taken " .. old_path)
        local new_path = path.."/"..obs.os_generate_formatted_filename("png",true,prefix..scene_name)
        obs.os_rename(old_path, new_path)
        print("moved to " .. new_path)
        next_screenshot = true
     end
end

function script_properties()
	local props = obs.obs_properties_create()
    obs.obs_properties_add_path(props, "path", "Path", obs.OBS_PATH_DIRECTORY, NIL, NIL)
    obs.obs_properties_add_text(props,"prefix","Filename prefix", obs.OBS_TEXT_DEFAULT)
    obs.obs_properties_add_button(props,"go","Go", go)
    return props
end

function script_defaults(settings)
    local sc = obs.obs_frontend_get_current_scene_collection()
    if sc ~= nil and sc ~= "" then
        obs.obs_data_set_default_string(settings, "prefix", sc.." - ")
    end
end

function script_update(settings)
    path = obs.obs_data_get_string(settings, "path")
    prefix = obs.obs_data_get_string(settings, "prefix")
end

function script_load(settings)
    obs.obs_frontend_add_event_callback(frontend_event)
    script_update(settings)
end

function script_save(settings)

end