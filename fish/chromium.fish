function deps --description "run gclient sync"
    # --reset drops local changes. often great, but if making changes inside v8, you don't want to use --reset
    # also reset seems to reset branch position in the devtools-internal repo??? weird.
    env gclient sync --delete_unversioned_trees --jobs=70
end

function hooks --description "run gclient runhooks"
    env gclient runhooks
end

function b --description "build chromium"
	set -l dir_default (grealpath $PWD/(git rev-parse --show-cdup)out/Default/)
    # autoninja is better than trying to set -j and -l manually.
    # and yay, nice cmd built-in, so no more need to do this:  `renice +19 -n (pgrep ninja); renice +19 -n (pgrep compiler_proxy)`
    set -l cmd "nice -n 19 autoninja -C "$dir_default" chrome"  # blink_tests  
    echo "  > $cmd"

    # start the compile
    eval $cmd

    if test $status = 0
        osascript -e 'display notification "" with title "✅ Chromium compile done"'
    else
        osascript -e 'display notification "" with title "❌ Chromium compile failed"'
    end

    # DISABLED this was cool bit also annoying
    # if test $status = 0
    #     echo ""
    #     echo "✅ Chrome build complete!  🕵️‍  Finishing blink_tests in the background..."
    #     eval "ninja -C $dir -j900 -l 48 blink_tests &"
    #     jobs
    # end
end


function dtb --description "build devtools"
    set -l dir_default (grealpath $PWD/(git rev-parse --show-cdup)out/Default/)
    set -l cmd "autoninja -C "$dir_default""  
    echo "  > $cmd"
    eval $cmd
end

function cr --description "open built chromium (accepts runtime flags)"
    set -l dir (git rev-parse --show-cdup)/out/Default
    set -l cmd "./$dir/Chromium.app/Contents/MacOS/Chromium --disable-features=DialMediaRouteProvider $argv"
    echo "  > $cmd"
    eval $cmd
end

function dtcr --description "run chrome with dev devtools"
    set -l crpath "$HOME/chromium-devtools/devtools-frontend/third_party/chrome/chrome-mac/Chromium.app/Contents/MacOS/Chromium"
    set -l dtpath (realpath out/Default/gen/front_end)
    set -l cmd "$crpath --custom-devtools-frontend=file://$dtpath --user-data-dir=$HOME/chromium-devtools/dt-chrome-profile --disable-features=DialMediaRouteProvider $argv"
    echo "  > $cmd"
    eval $cmd
end

function dtbcr --description "build chromium, then open it"
    if dtb
        dtcr
    end
end

function bcr --description "build chromium, then open it"
    if b
        cr
    end
end



function depsb --description "deps, then build chromium, then open it"
    if deps
        # #     if [ "$argv[1]" = "--skipgoma" ] ...
        gom
        b
    end
end

function depsbcr --description "deps, then build chromium, then open it"
    if deps
        # #     if [ "$argv[1]" = "--skipgoma" ] ...
        gom
        bcr
    end
end

function hooksbcr --description "run hooks, then build chromium, then open it"
    if hooks
        gom
        bcr
    end
end

function gom --description "run goma setup"
    set -x GOMAMAILTO /dev/null
    # set -x GOMA_OAUTH2_CONFIG_FILE /Users/paulirish/.goma_oauth2_config
    set -x GOMA_ENABLE_REMOTE_LINK yes

    goma_ctl ensure_start
    # maybe i dont need all this shit
    
    # if not test (curl -X POST --silent http://127.0.0.1:8088/api/accountz)
    #     echo "Goma isn't running. Starting it."
    #     ~/goma/goma_ctl.py ensure_start
    #     return 0
    # end

    # set -l local_goma_version (curl -X POST --silent http://127.0.0.1:8088/api/taskz | jq '.goma_version[0]')
    # set -l remote_goma_version (~/goma/goma_ctl.py latest_version | ack 'VERSION=(\d+)' | ack -o '\d+')

    # if test local_goma_version = remote_goma_version
    #     echo 'Goma is running and up to date, continuing.'
    # else
    #     echo 'Goma needs an update. Stopping and restarting.'
    #     ~/goma/goma_ctl.py stop
    #     ~/goma/goma_ctl.py ensure_start
    # end
end
