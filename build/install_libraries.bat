@echo off
echo Installing all required libraries.

REM haxelib --global update haxelib
REM haxelib fixrepo
haxelib git hxcpp https://github.com/Vortex2Oblivion/hxcpp-compiled
haxelib install format
haxelib install hxp
haxelib --skip-dependencies git lime https://github.com/vortex2oblivion/lime
haxelib --skip-dependencies git openfl https://github.com/Vortex2Oblivion/openfl
haxelib --skip-dependencies git flixel https://github.com/Vortex2Oblivion/flixel dev
haxelib --skip-dependencies git flixel-addons https://github.com/vortex2oblivion/flixel-addons dev
haxelib git flixel-ui https://github.com/Vortex2Oblivion/flixel-ui
haxelib git linc_luajit https://github.com/Leather128/linc_luajit.git
haxelib git hscript-improved https://github.com/CodenameCrew/hscript-improved fe673c21b278819805aaa730216ec527c2507443
haxelib git scriptless-polymod https://github.com/Vortex2Oblivion/scriptless-polymod
haxelib git hxNoise https://github.com/whuop/hxNoise
haxelib git hxvlc https://github.com/Vortex2Oblivion/hxvlc
haxelib --skip-dependencies install hxdiscord_rpc
haxelib git fnf-modcharting-tools https://github.com/Vortex2Oblivion/FNF-Modcharting-Tools
haxelib git flxanimate https://github.com/Vortex2Oblivion/flxanimate
haxelib git thx.core https://github.com/fponticelli/thx.core
haxelib git thx.semver https://github.com/fponticelli/thx.semver.git
haxelib git grig.audio https://github.com/FunkinCrew/grig.audio refactor/fft-cam-version
haxelib git funkin.vis https://github.com/FunkinCrew/funkVis
haxelib git jsonpath https://github.com/EliteMasterEric/jsonpath
haxelib --skip-dependencies git jsonpatch https://github.com/EliteMasterEric/jsonpatch
haxelib install hxcpp-debug-server
haxelib --always run lime rebuild windows
haxelib --always run lime setup

echo Finished
