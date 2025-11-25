
function getApplication(appName)
    for _, app in pairs(hs.application.runningApplications()) do
        -- dbgf("app name :: %s",app:name())
        -- dbgf("app pid :: %s",app:pid())
        if app:pid() then
            if appName == app:name() then
                return app
            end
        end
    end
end

function findApplication(applicationName)

    return hs.fnutils.filter(hs.application.runningApplications(), function(app)
        return result(app, 'title') == applicationName
    end)
end

function getApplicationWindow(app)
    if app and #app then
        windows = app[1]:allWindows()
        window = windows[1]
        return window
    else
        return nil
    end
end

function getWindowFrame(window)
    -- local windowFrame = window:frame()
    -- win:screen():frame()
end
